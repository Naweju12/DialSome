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

public class WebRTCManager {
    private static final String TAG = "WebRTCManager";
    private PeerConnectionFactory factory;
    private PeerConnection peerConnection;
    private AudioSource audioSource;
    private AudioTrack localAudioTrack;
    private AudioManager audioManager;
    private Context mContext;

    // Native callbacks to C++
    public native void onLocalIceCandidate(String sdp, String sdpMid, int sdpMLineIndex);
    public native void onLocalSdp(String sdp, String type);
    public native void onCallEstablished();
    public native void onCallDisconnected();

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

            // Modern replacement for setSpeakerphoneOn(true) for API 31+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                List<AudioDeviceInfo> devices = audioManager.getAvailableCommunicationDevices();
                AudioDeviceInfo speakerDevice = null;
                for (AudioDeviceInfo device : devices) {
                    if (device.getType() == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER) {
                        speakerDevice = device;
                        break;
                    }
                }
                if (speakerDevice != null) {
                    audioManager.setCommunicationDevice(speakerDevice);
                }
            } else {
                // Fallback for older versions (suppressed warning)
                audioManager.setSpeakerphoneOn(true);
            }
        } else {
            audioManager.setMode(AudioManager.MODE_NORMAL);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                audioManager.clearCommunicationDevice();
            }
        }
    }

    public void createPeerConnection() {
        PeerConnection.RTCConfiguration config = new PeerConnection.RTCConfiguration(
            Collections.singletonList(PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer())
        );

        peerConnection = factory.createPeerConnection(config, new PeerConnection.Observer() {
            @Override public void onIceCandidate(IceCandidate iceCandidate) {
                onLocalIceCandidate(iceCandidate.sdp, iceCandidate.sdpMid, iceCandidate.sdpMLineIndex);
            }

            @Override public void onIceConnectionChange(PeerConnection.IceConnectionState newState) {
                Log.d(TAG, "ICE State Change: " + newState);
                if (newState == PeerConnection.IceConnectionState.CONNECTED ||
                    newState == PeerConnection.IceConnectionState.COMPLETED) {
                    if (mContext != null) {
                        Intent serviceIntent = new Intent(mContext, CallForegroundService.class);
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            mContext.startForegroundService(serviceIntent);
                        } else {
                            mContext.startService(serviceIntent);
                        }
                    }

                    onCallEstablished();
                }
                else if (newState == PeerConnection.IceConnectionState.DISCONNECTED ||
                         newState == PeerConnection.IceConnectionState.FAILED ||
                         newState == PeerConnection.IceConnectionState.CLOSED) {
                    onCallDisconnected();
                }
            }

            @Override public void onTrack(RtpTransceiver transceiver) {
                Log.d(TAG, "Remote track received: " + transceiver.getReceiver().track().kind());
            }

            @Override public void onSignalingChange(PeerConnection.SignalingState s) { Log.d(TAG, "Signaling: " + s); }
            @Override public void onIceConnectionReceivingChange(boolean b) {}
            @Override public void onIceGatheringChange(PeerConnection.IceGatheringState s) {}
            @Override public void onIceCandidatesRemoved(IceCandidate[] i) {}
            @Override public void onAddStream(MediaStream m) {}
            @Override public void onRemoveStream(MediaStream m) {}
            @Override public void onDataChannel(DataChannel d) {}
            @Override public void onRenegotiationNeeded() {}
        });

        // Initialize local audio track if not already done
        if (localAudioTrack == null) {
            audioSource = factory.createAudioSource(new MediaConstraints());
            localAudioTrack = factory.createAudioTrack("ARDAMSa0", audioSource);
            localAudioTrack.setEnabled(true);
        }

        // Add the track to PeerConnection to ensure bidirectional "sendrecv" in SDP
        peerConnection.addTrack(localAudioTrack, Collections.singletonList("ARDAMS"));
    }

    public void createOffer() {
        MediaConstraints constraints = new MediaConstraints();
        constraints.mandatory.add(new MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"));

        peerConnection.createOffer(new SimpleSdpObserver() {
            @Override public void onCreateSuccess(SessionDescription sdp) {
                peerConnection.setLocalDescription(new SimpleSdpObserver(), sdp);
                onLocalSdp(sdp.description, sdp.type.canonicalForm());
            }
        }, constraints);
    }

    public void handleRemoteSdp(String sdp, String type) {
        if (peerConnection == null) return;

        SessionDescription remoteSdp = new SessionDescription(
            SessionDescription.Type.fromCanonicalForm(type), sdp);

        peerConnection.setRemoteDescription(new SimpleSdpObserver() {
            @Override public void onSetSuccess() {
                if (remoteSdp.type == SessionDescription.Type.OFFER) {
                    createAnswer();
                }
            }
        }, remoteSdp);
    }

    private void createAnswer() {
        MediaConstraints constraints = new MediaConstraints();
        constraints.mandatory.add(new MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"));

        peerConnection.createAnswer(new SimpleSdpObserver() {
            @Override public void onCreateSuccess(SessionDescription sdp) {
                peerConnection.setLocalDescription(new SimpleSdpObserver(), sdp);
                onLocalSdp(sdp.description, sdp.type.canonicalForm());
            }
        }, constraints);
    }

    public void addRemoteIceCandidate(String sdp, String sdpMid, int sdpMLineIndex) {
        if (peerConnection != null) {
            peerConnection.addIceCandidate(new IceCandidate(sdpMid, sdpMLineIndex, sdp));
        }
    }

    public void close() {
        if (mContext != null) {
            Intent serviceIntent = new Intent(mContext, CallForegroundService.class);
            mContext.stopService(serviceIntent);
        }

        setupAudioManager(false);
        if (peerConnection != null) peerConnection.dispose();
        if (localAudioTrack != null) localAudioTrack.dispose();
        if (audioSource != null) audioSource.dispose();
        if (factory != null) factory.dispose();
    }

    private class SimpleSdpObserver implements SdpObserver {
        @Override public void onCreateSuccess(SessionDescription s) {}
        @Override public void onSetSuccess() {}
        @Override public void onCreateFailure(String s) { Log.e(TAG, "SDP Create Failure: " + s); }
        @Override public void onSetFailure(String s) { Log.e(TAG, "SDP Set Failure: " + s); }
    }
}
