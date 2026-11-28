import 'dart:convert';

/// Builds a self-contained HTML5 + hls.js video player page for Android/iOS WebView.
/// This avoids Android ExoPlayer PesReader / renderFps=0 issues on PhimAPI HLS streams
/// while preserving full programmatic Watch Party sync (pre-seek, smooth playbackRate,
/// Host play/pause/seek, and real-time position reporting via JavaScriptChannel).
String buildWatchPartyHlsHtml({
  required String streamUrl,
  required double startTimeSec,
  required bool autoPlay,
  required int rttMs,
}) {
  final encodedUrl = jsonEncode(streamUrl);
  final safeStart = startTimeSec < 0 ? 0.0 : startTimeSec;
  final safeRtt = rttMs < 0 ? 0 : rttMs;

  return '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      width: 100%;
      height: 100%;
      background: #000;
      overflow: hidden;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    video {
      width: 100%;
      height: 100%;
      object-fit: contain;
      background: #000;
    }
  </style>
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1.5.17/dist/hls.min.js"></script>
</head>
<body>
  <video id="wpVideo" playsinline webkit-playsinline preload="auto"></video>
  <script>
    (function() {
      var video = document.getElementById('wpVideo');
      var hls = null;
      var mountTs = Date.now();
      var rttMs = $safeRtt;
      var lastEmitTs = 0;

      function post(type, extra) {
        try {
          if (window.WatchPartyPlayer && window.WatchPartyPlayer.postMessage) {
            var payload = Object.assign({
              type: type,
              currentTime: Number.isFinite(video.currentTime) ? video.currentTime : 0,
              duration: Number.isFinite(video.duration) ? video.duration : 0,
              isPlaying: !video.paused && !video.ended
            }, extra || {});
            window.WatchPartyPlayer.postMessage(JSON.stringify(payload));
          }
        } catch (e) {}
      }

      function safePlay() {
        video.muted = false;
        var p = video.play();
        if (p && typeof p.catch === 'function') {
          p.catch(function() {
            video.muted = true;
            video.play().then(function() {
              setTimeout(function() { video.muted = false; }, 350);
            }).catch(function() {
              post('autoplay_blocked');
            });
          });
        }
      }

      function loadSource(url, startSec, shouldPlay) {
        mountTs = Date.now();
        if (hls) {
          try { hls.destroy(); } catch (e) {}
          hls = null;
        }
        var target = Math.max(0, Number(startSec) || 0);
        post('buffering', { isBuffering: true });

        var isM3u8 = (url || '').toLowerCase().indexOf('.m3u8') !== -1;
        if (isM3u8 && window.Hls && window.Hls.isSupported()) {
          var retries = 0;
          hls = new window.Hls({
            startPosition: target > 1 ? target : -1,
            autoStartLoad: false,
            enableWorker: true,
            lowLatencyMode: false,
            maxBufferLength: 20,
            maxMaxBufferLength: 40
          });
          hls.loadSource(url);
          hls.attachMedia(video);
          hls.on(window.Hls.Events.MANIFEST_PARSED, function() {
            var deltaLoad = (Date.now() - mountTs) / 1000;
            var tFinal = (shouldPlay && target > 1)
              ? target + deltaLoad + (rttMs / 2000)
              : target;
            hls.startLoad(tFinal > 1 ? tFinal : -1);
            if (tFinal > 0.5) {
              try { video.currentTime = tFinal; } catch (e) {}
            }
            post('ready');
            if (shouldPlay) {
              safePlay();
            } else {
              video.pause();
            }
          });
          hls.on(window.Hls.Events.ERROR, function(_evt, data) {
            if (data && data.fatal) {
              if (data.type === window.Hls.ErrorTypes.NETWORK_ERROR && retries < 2) {
                retries++;
                hls.startLoad();
              } else if (data.type === window.Hls.ErrorTypes.MEDIA_ERROR) {
                hls.recoverMediaError();
              } else {
                post('error', { message: 'Lỗi tải luồng HLS (' + (data.details || data.type) + ')' });
              }
            }
          });
        } else {
          video.src = url;
          video.onloadedmetadata = function() {
            var deltaLoad = (Date.now() - mountTs) / 1000;
            var tFinal = (shouldPlay && target > 1)
              ? target + deltaLoad + (rttMs / 2000)
              : target;
            if (tFinal > 0.5) {
              try { video.currentTime = tFinal; } catch (e) {}
            }
            post('ready');
            if (shouldPlay) {
              safePlay();
            } else {
              video.pause();
            }
          };
          video.onerror = function() {
            post('error', { message: 'Không thể phát nguồn video này.' });
          };
        }
      }

      video.addEventListener('playing', function() {
        post('playing', { isBuffering: false });
      });
      video.addEventListener('pause', function() {
        post('pause', { isBuffering: false });
      });
      video.addEventListener('waiting', function() {
        post('buffering', { isBuffering: true });
      });
      video.addEventListener('canplay', function() {
        post('buffering', { isBuffering: false });
      });
      video.addEventListener('timeupdate', function() {
        var now = Date.now();
        if (now - lastEmitTs >= 400) {
          lastEmitTs = now;
          post('timeupdate', { isBuffering: false });
        }
      });

      window.wpPlayer = {
        play: function() {
          safePlay();
        },
        pause: function() {
          video.pause();
        },
        seek: function(sec) {
          var s = Math.max(0, Number(sec) || 0);
          try { video.currentTime = s; } catch (e) {}
          post('timeupdate');
        },
        setRate: function(rate) {
          try { video.playbackRate = Number(rate) || 1.0; } catch (e) {}
        },
        syncState: function(targetSec, isPlaying, forceSeek) {
          var s = Math.max(0, Number(targetSec) || 0);
          var dt = s - (video.currentTime || 0);
          var absDt = Math.abs(dt);
          if (!isPlaying) {
            video.playbackRate = 1.0;
            if (absDt > 0.8) {
              try { video.currentTime = s; } catch (e) {}
            }
            video.pause();
            return;
          }
          if (forceSeek || absDt > 2.0) {
            video.playbackRate = 1.0;
            try { video.currentTime = s; } catch (e) {}
          } else if (absDt > 0.45) {
            video.playbackRate = dt > 0 ? 1.05 : 0.95;
            setTimeout(function() { video.playbackRate = 1.0; }, 2500);
          } else {
            video.playbackRate = 1.0;
          }
          safePlay();
        },
        loadSource: loadSource
      };

      loadSource($encodedUrl, $safeStart, ${autoPlay ? 'true' : 'false'});

      // ─── WebRTC P2P Mesh Voice Chat (tương thích 100% với bản Web) ─────────
      var myUserId = '';
      var roomPeerIds = [];
      var localStream = null;
      var voiceMuted = true;
      var peers = {};
      var pendingCandidates = {};
      var remoteAudios = {};
      var audioCtx = null;
      var speakTimer = null;
      var duckTimer = null;
      var isDucked = false;
      var RTC_CFG = {
        iceServers: [
          { urls: 'stun:stun.l.google.com:19302' },
          { urls: 'stun:stun1.l.google.com:19302' }
        ]
      };

      function applyDucking(active) {
        try {
          if (active) {
            if (duckTimer) { clearTimeout(duckTimer); duckTimer = null; }
            if (!isDucked) { video.volume = 0.35; isDucked = true; }
          } else if (isDucked) {
            duckTimer = setTimeout(function() {
              try { video.volume = 1.0; isDucked = false; } catch (e) {}
            }, 1000);
          }
        } catch (e) {}
      }

      function ensureLocalStream() {
        if (localStream) return Promise.resolve(localStream);
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          post('voice_error', { message: 'Thiết bị không hỗ trợ micro WebRTC.' });
          return Promise.resolve(null);
        }
        return navigator.mediaDevices.getUserMedia({
          audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
          video: false
        }).then(function(stream) {
          localStream = stream;
          stream.getAudioTracks().forEach(function(t) { t.enabled = !voiceMuted; });
          Object.keys(peers).forEach(function(pid) {
            var pc = peers[pid];
            if (!pc) return;
            var senders = pc.getSenders();
            stream.getAudioTracks().forEach(function(track) {
              if (!senders.some(function(s) { return s.track && s.track.id === track.id; })) {
                pc.addTrack(track, stream);
              }
            });
          });
          try {
            var AC = window.AudioContext || window.webkitAudioContext;
            if (AC && !audioCtx) {
              audioCtx = new AC();
              var src = audioCtx.createMediaStreamSource(stream);
              var analyser = audioCtx.createAnalyser();
              analyser.fftSize = 256;
              src.connect(analyser);
              var buf = new Uint8Array(analyser.frequencyBinCount);
              var lastSpeak = false;
              speakTimer = setInterval(function() {
                if (voiceMuted) {
                  if (lastSpeak) {
                    lastSpeak = false;
                    post('voice_speaking', { isSpeaking: false });
                  }
                  return;
                }
                analyser.getByteFrequencyData(buf);
                var sum = 0;
                for (var i = 0; i < buf.length; i++) sum += buf[i];
                var avg = sum / buf.length;
                var speaking = avg > 22;
                if (speaking !== lastSpeak) {
                  lastSpeak = speaking;
                  post('voice_speaking', { isSpeaking: speaking });
                  applyDucking(speaking);
                }
              }, 220);
            }
          } catch (e) {}
          return stream;
        }).catch(function(err) {
          post('voice_error', { message: 'Không thể bật micro: ' + (err && err.message ? err.message : err) });
          return null;
        });
      }

      function getOrCreatePeer(targetId) {
        if (peers[targetId]) return peers[targetId];
        var pc = new RTCPeerConnection(RTC_CFG);
        if (localStream) {
          localStream.getTracks().forEach(function(t) { pc.addTrack(t, localStream); });
        }
        pc.onicecandidate = function(ev) {
          if (ev.candidate) {
            post('voice_signal', {
              targetUserId: targetId,
              signal: { type: 'candidate', candidate: ev.candidate.toJSON() }
            });
          }
        };
        pc.ontrack = function(ev) {
          var rs = (ev.streams && ev.streams[0]) ? ev.streams[0] : new MediaStream([ev.track]);
          var el = remoteAudios[targetId];
          if (!el) {
            el = document.createElement('audio');
            el.autoplay = true;
            el.setAttribute('playsinline', 'true');
            document.body.appendChild(el);
            remoteAudios[targetId] = el;
          }
          el.srcObject = rs;
          el.play().catch(function() {});
        };
        pc.onconnectionstatechange = function() {
          if (pc.connectionState === 'failed' || pc.connectionState === 'closed') {
            delete peers[targetId];
          }
        };
        peers[targetId] = pc;
        return pc;
      }

      function createOfferFor(targetId) {
        var pc = getOrCreatePeer(targetId);
        pc.createOffer({ offerToReceiveAudio: true }).then(function(offer) {
          return pc.setLocalDescription(offer).then(function() {
            post('voice_signal', {
              targetUserId: targetId,
              signal: { type: 'offer', sdp: pc.localDescription }
            });
          });
        }).catch(function() {});
      }

      function flushCandidates(peerId, pc) {
        var q = pendingCandidates[peerId] || [];
        delete pendingCandidates[peerId];
        q.forEach(function(c) {
          pc.addIceCandidate(new RTCIceCandidate(c)).catch(function() {});
        });
      }

      window.wpVoice = {
        setSelf: function(uid) {
          myUserId = uid || '';
        },
        setMuted: function(muted) {
          voiceMuted = !!muted;
          Object.keys(remoteAudios).forEach(function(pid) {
            try { remoteAudios[pid].play().catch(function() {}); } catch (e) {}
          });
          if (!voiceMuted) {
            ensureLocalStream().then(function(stream) {
              if (!stream) return;
              stream.getAudioTracks().forEach(function(t) { t.enabled = true; });
              if (audioCtx && audioCtx.state === 'suspended') {
                audioCtx.resume().catch(function() {});
              }
              var allTargets = roomPeerIds.slice();
              Object.keys(peers).forEach(function(pid) {
                if (allTargets.indexOf(pid) === -1) allTargets.push(pid);
              });
              allTargets.forEach(function(pid) {
                if (!pid || pid === myUserId) return;
                var pc = getOrCreatePeer(pid);
                var senders = pc.getSenders();
                stream.getAudioTracks().forEach(function(track) {
                  if (!senders.some(function(s) { return s.track && s.track.id === track.id; })) {
                    pc.addTrack(track, stream);
                  }
                });
                createOfferFor(pid);
              });
            });
          } else if (localStream) {
            localStream.getAudioTracks().forEach(function(t) { t.enabled = false; });
          }
        },
        setAnySpeaking: function(speaking) {
          applyDucking(!!speaking);
        },
        syncPeers: function(memberIds) {
          if (!myUserId || !Array.isArray(memberIds)) return;
          roomPeerIds = memberIds.filter(function(pid) { return pid && pid !== myUserId; });
          roomPeerIds.forEach(function(pid) {
            if (!peers[pid] && myUserId < pid) {
              createOfferFor(pid);
            }
          });
          Object.keys(peers).forEach(function(pid) {
            if (roomPeerIds.indexOf(pid) === -1) {
              window.wpVoice.disconnectPeer(pid);
            }
          });
        },
        handleSignal: function(fromId, signal) {
          if (!fromId || !signal) return;
          var pc = getOrCreatePeer(fromId);
          if (signal.type === 'offer' && signal.sdp) {
            pc.setRemoteDescription(new RTCSessionDescription(signal.sdp)).then(function() {
              if (localStream) {
                var senders = pc.getSenders();
                localStream.getAudioTracks().forEach(function(track) {
                  if (!senders.some(function(s) { return s.track && s.track.id === track.id; })) {
                    pc.addTrack(track, localStream);
                  }
                });
              }
              flushCandidates(fromId, pc);
              return pc.createAnswer();
            }).then(function(ans) {
              return pc.setLocalDescription(ans).then(function() {
                post('voice_signal', {
                  targetUserId: fromId,
                  signal: { type: 'answer', sdp: pc.localDescription }
                });
              });
            }).catch(function() {});
          } else if (signal.type === 'answer' && signal.sdp) {
            pc.setRemoteDescription(new RTCSessionDescription(signal.sdp)).then(function() {
              flushCandidates(fromId, pc);
            }).catch(function() {});
          } else if (signal.type === 'candidate' && signal.candidate) {
            if (pc.remoteDescription && pc.remoteDescription.type) {
              pc.addIceCandidate(new RTCIceCandidate(signal.candidate)).catch(function() {});
            } else {
              pendingCandidates[fromId] = pendingCandidates[fromId] || [];
              pendingCandidates[fromId].push(signal.candidate);
            }
          }
        },
        disconnectPeer: function(pid) {
          if (peers[pid]) {
            try { peers[pid].close(); } catch (e) {}
            delete peers[pid];
          }
          if (remoteAudios[pid]) {
            try { remoteAudios[pid].srcObject = null; remoteAudios[pid].remove(); } catch (e) {}
            delete remoteAudios[pid];
          }
        }
      };
    })();
  </script>
</body>
</html>
''';
}
