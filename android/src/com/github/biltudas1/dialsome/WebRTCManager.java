package com.github.biltudas1.dialsome;

import android.content.Context;
import android.content.Intent;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.os.Build;
import android.util.Log;
import org.webrtc.*;
import org.webrtc.audio.AudioDeviceModule;
import org.webrtc.audio.JavaAudioDeviceModule;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class WebRTCManager {
    private static final String TAG = "WebRTCManager";
    private PeerConnectionFactory factory;
    private final Map<String, PeerConnection> peerConnections = new ConcurrentHashMap<>();
    private final Map<String, List<IceCandidate>> queuedRemoteCandidates = new ConcurrentHashMap<>();
    private AudioSource audioSource;
    private AudioTrack localAudioTrack;
    private AudioManager audioManager;
    private Context mContext;
    private boolean isForegroundServiceStarted = false;

    // Native callbacks to C++ (updated with peerEmail)
    public native void onLocalIceCandidate(String peerEmail, String sdp, String sdpMid, int sdpMLineIndex);
    public native void onLocalSdp(String peerEmail, String sdp, String type);
    public native void onCallEstablished(String peerEmail);
    public native void onCallDisconnected(String peerEmail);

    public void init(Context context) {
        this.mContext = context;

        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .createInitializationOptions()
        );

        audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        setupAudioManager(true);

        // Explicitly create the Audio Device Module to handle recording/playout hardware
        AudioDeviceModule adm = JavaAudioDeviceModule.builder(context)
            .setUseHardwareAcousticEchoCanceler(true)
            .setUseHardwareNoiseSuppressor(true)
            .createAudioDeviceModule();

        factory = PeerConnectionFactory.builder()
            .setAudioDeviceModule(adm)
            .createPeerConnectionFactory();

        // The factory takes ownership or references the adm; we can release our local reference
        adm.release();
    }

    @SuppressWarnings("deprecation")
    private void setupAudioManager(boolean enable) {
        if (audioManager == null) return;
        if (enable) {
            audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
            audioManager.setMicrophoneMute(false);

            // Modern replacement for API 31+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                List<AudioDeviceInfo> devices = audioManager.getAvailableCommunicationDevices();
                AudioDeviceInfo earpieceDevice = null;
                for (AudioDeviceInfo device : devices) {
                    if (device.getType() == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE) {
                        earpieceDevice = device;
                        break;
                    }
                }
                if (earpieceDevice != null) {
                    audioManager.setCommunicationDevice(earpieceDevice);
                }
            } else {
                // Fallback for older versions: ensure speaker is OFF by default
                audioManager.setSpeakerphoneOn(false);
            }
        } else {
            audioManager.setMode(AudioManager.MODE_NORMAL);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                audioManager.clearCommunicationDevice();
            }
        }
    }

    public void setSpeaker(boolean enable) {
        if (audioManager == null) return;
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            List<AudioDeviceInfo> devices = audioManager.getAvailableCommunicationDevices();
            AudioDeviceInfo targetDevice = null;
            
            // Choose between loudspeaker and earpiece
            int targetType = enable ? AudioDeviceInfo.TYPE_BUILTIN_SPEAKER : AudioDeviceInfo.TYPE_BUILTIN_EARPIECE;
            
            for (AudioDeviceInfo device : devices) {
                if (device.getType() == targetType) {
                    targetDevice = device;
                    break;
                }
            }
            if (targetDevice != null) {
                audioManager.setCommunicationDevice(targetDevice);
            }
        } else {
            // Fallback for older Android versions
            audioManager.setSpeakerphoneOn(enable);
        }
    }

    public void setPeerMuted(final String peerEmail, final boolean mute) {
        PeerConnection pc = peerConnections.get(peerEmail);
        if (pc != null) {
            Log.d(TAG, "Setting peer muted: " + peerEmail + " = " + mute);
            for (RtpSender sender : pc.getSenders()) {
                MediaStreamTrack track = sender.track();
                if (track != null && track.kind().equals("audio")) {
                    sender.setTrack(mute ? null : localAudioTrack, false);
                }
            }
        }
    }

    public void setMicrophoneMuted(final boolean mute) {
        synchronized (this) {
            if (localAudioTrack != null) {
                localAudioTrack.setEnabled(!mute);
                Log.d(TAG, "Local audio track enabled: " + !mute);
            }
        }
    }

    public void createPeerConnection(final String peerEmail) {
        if (peerConnections.containsKey(peerEmail)) {
            Log.d(TAG, "PeerConnection for " + peerEmail + " already exists.");
            return;
        }

        PeerConnection.RTCConfiguration config = new PeerConnection.RTCConfiguration(
            Collections.singletonList(PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer())
        );

        PeerConnection pc = factory.createPeerConnection(config, new PeerConnection.Observer() {
            @Override public void onIceCandidate(IceCandidate iceCandidate) {
                onLocalIceCandidate(peerEmail, iceCandidate.sdp, iceCandidate.sdpMid, iceCandidate.sdpMLineIndex);
            }

            @Override public void onIceConnectionChange(PeerConnection.IceConnectionState newState) {
                Log.d(TAG, "ICE State for " + peerEmail + ": " + newState);
                if (newState == PeerConnection.IceConnectionState.CONNECTED ||
                    newState == PeerConnection.IceConnectionState.COMPLETED) {
                    
                    synchronized (WebRTCManager.this) {
                        if (!isForegroundServiceStarted && mContext != null) {
                            Intent serviceIntent = new Intent(mContext, CallForegroundService.class);
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                mContext.startForegroundService(serviceIntent);
                            } else {
                                mContext.startService(serviceIntent);
                            }
                            isForegroundServiceStarted = true;
                        }
                    }

                    onCallEstablished(peerEmail);
                }
                else if (newState == PeerConnection.IceConnectionState.DISCONNECTED ||
                         newState == PeerConnection.IceConnectionState.FAILED ||
                         newState == PeerConnection.IceConnectionState.CLOSED) {
                    onCallDisconnected(peerEmail);
                }
            }

            @Override public void onTrack(RtpTransceiver transceiver) {
                Log.d(TAG, "Remote track received from " + peerEmail + ": " + transceiver.getReceiver().track().kind());
            }

            @Override public void onSignalingChange(PeerConnection.SignalingState s) { Log.d(TAG, "Signaling for " + peerEmail + ": " + s); }
            @Override public void onIceConnectionReceivingChange(boolean b) {}
            @Override public void onIceGatheringChange(PeerConnection.IceGatheringState s) {}
            @Override public void onIceCandidatesRemoved(IceCandidate[] i) {}
            @Override public void onAddStream(MediaStream m) {}
            @Override public void onRemoveStream(MediaStream m) {}
            @Override public void onDataChannel(DataChannel d) {}
            @Override public void onRenegotiationNeeded() {}
        });

        // Initialize local audio track if not already done (shared resource)
        synchronized (this) {
            if (localAudioTrack == null) {
                audioSource = factory.createAudioSource(new MediaConstraints());
                localAudioTrack = factory.createAudioTrack("ARDAMSa0", audioSource);
                localAudioTrack.setEnabled(true);
            }
        }

        // Add the track to PeerConnection to ensure bidirectional "sendrecv" in SDP
        pc.addTrack(localAudioTrack, Collections.singletonList("ARDAMS"));
        peerConnections.put(peerEmail, pc);
    }

    public void createOffer(final String peerEmail) {
        final PeerConnection pc = peerConnections.get(peerEmail);
        if (pc == null) return;

        MediaConstraints constraints = new MediaConstraints();
        constraints.mandatory.add(new MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"));

        pc.createOffer(new SimpleSdpObserver() {
            @Override public void onCreateSuccess(SessionDescription sdp) {
                pc.setLocalDescription(new SimpleSdpObserver(), sdp);
                onLocalSdp(peerEmail, sdp.description, sdp.type.canonicalForm());
            }
        }, constraints);
    }

    public void handleRemoteSdp(final String peerEmail, String sdp, String type) {
        final PeerConnection pc = peerConnections.get(peerEmail);
        if (pc == null) return;

        final SessionDescription remoteSdp = new SessionDescription(
            SessionDescription.Type.fromCanonicalForm(type), sdp);

        pc.setRemoteDescription(new SimpleSdpObserver() {
            @Override public void onSetSuccess() {
                drainQueuedCandidates(peerEmail);
                if (remoteSdp.type == SessionDescription.Type.OFFER) {
                    createAnswer(peerEmail);
                }
            }
        }, remoteSdp);
    }

    private void drainQueuedCandidates(final String peerEmail) {
        PeerConnection pc = peerConnections.get(peerEmail);
        if (pc == null) return;
        List<IceCandidate> queued = queuedRemoteCandidates.remove(peerEmail);
        if (queued != null) {
            Log.d(TAG, "Draining " + queued.size() + " queued remote ICE candidates for: " + peerEmail);
            for (IceCandidate cand : queued) {
                pc.addIceCandidate(cand);
            }
        }
    }

    private void createAnswer(final String peerEmail) {
        final PeerConnection pc = peerConnections.get(peerEmail);
        if (pc == null) return;

        MediaConstraints constraints = new MediaConstraints();
        constraints.mandatory.add(new MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"));

        pc.createAnswer(new SimpleSdpObserver() {
            @Override public void onCreateSuccess(SessionDescription sdp) {
                pc.setLocalDescription(new SimpleSdpObserver(), sdp);
                onLocalSdp(peerEmail, sdp.description, sdp.type.canonicalForm());
            }
        }, constraints);
    }

    public void addRemoteIceCandidate(final String peerEmail, String sdp, String sdpMid, int sdpMLineIndex) {
        PeerConnection pc = peerConnections.get(peerEmail);
        IceCandidate candidate = new IceCandidate(sdpMid, sdpMLineIndex, sdp);
        if (pc != null) {
            pc.addIceCandidate(candidate);
        } else {
            Log.d(TAG, "Queueing remote ICE candidate for: " + peerEmail);
            if (!queuedRemoteCandidates.containsKey(peerEmail)) {
                queuedRemoteCandidates.put(peerEmail, Collections.synchronizedList(new java.util.ArrayList<IceCandidate>()));
            }
            queuedRemoteCandidates.get(peerEmail).add(candidate);
        }
    }

    public void closePeer(final String peerEmail) {
        queuedRemoteCandidates.remove(peerEmail);
        PeerConnection pc = peerConnections.remove(peerEmail);
        if (pc != null) {
            pc.dispose();
            Log.d(TAG, "Closed and disposed peer connection for: " + peerEmail);
        }

        // If no more active peer connections, stop the foreground service
        synchronized (this) {
            if (peerConnections.isEmpty() && isForegroundServiceStarted) {
                if (mContext != null) {
                    Intent serviceIntent = new Intent(mContext, CallForegroundService.class);
                    mContext.stopService(serviceIntent);
                }
                isForegroundServiceStarted = false;
            }
        }
    }

    public void close() {
        synchronized (this) {
            if (mContext != null && isForegroundServiceStarted) {
                Intent serviceIntent = new Intent(mContext, CallForegroundService.class);
                mContext.stopService(serviceIntent);
                isForegroundServiceStarted = false;
            }
        }

        setupAudioManager(false);

        for (Map.Entry<String, PeerConnection> entry : peerConnections.entrySet()) {
            entry.getValue().dispose();
        }
        peerConnections.clear();
        queuedRemoteCandidates.clear();

        if (localAudioTrack != null) {
            localAudioTrack.dispose();
            localAudioTrack = null;
        }
        if (audioSource != null) {
            audioSource.dispose();
            audioSource = null;
        }
        if (factory != null) {
            factory.dispose();
            factory = null;
        }
    }

    private class SimpleSdpObserver implements SdpObserver {
        @Override public void onCreateSuccess(SessionDescription s) {}
        @Override public void onSetSuccess() {}
        @Override public void onCreateFailure(String s) { Log.e(TAG, "SDP Create Failure: " + s); }
        @Override public void onSetFailure(String s) { Log.e(TAG, "SDP Set Failure: " + s); }
    }
}
