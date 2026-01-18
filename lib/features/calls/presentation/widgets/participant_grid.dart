import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class ParticipantGrid extends StatelessWidget {
  final int localUid;
  final List<int> remoteUids;
  final RtcEngine? engine;

  const ParticipantGrid({
    Key? key,
    required this.localUid,
    required this.remoteUids,
    required this.engine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalParticipants = remoteUids.length + 1;

    if (totalParticipants == 1) {
      // Only local user (waiting for others)
      return _buildLocalView();
    } else if (totalParticipants == 2) {
      // 1-on-1 call
      return _buildOneOnOneLayout();
    } else if (totalParticipants <= 4) {
      // 2x2 grid
      return _buildGridLayout(2);
    } else {
      // 3x3 grid (max 9 participants)
      return _buildGridLayout(3);
    }
  }

  Widget _buildLocalView() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Local video
          if (engine != null)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: engine!,
                canvas: VideoCanvas(uid: 0),
              ),
            )
          else
            Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // Waiting text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 200), // Push text down
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Waiting for others to join...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOneOnOneLayout() {
    return Stack(
      children: [
        // Remote user (full screen)
        Container(
          color: Colors.black,
          child: engine != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: engine!,
                    canvas: VideoCanvas(uid: remoteUids.first),
                    connection: RtcConnection(channelId: ''),
                  ),
                )
              : Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
        
        // Local user (small overlay - top right)
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  if (engine != null)
                    AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: engine!,
                        canvas: VideoCanvas(uid: 0),
                      ),
                    )
                  else
                    Center(
                      child: Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                  
                  // "You" label
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'You',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridLayout(int columns) {
    final allUids = [0, ...remoteUids]; // 0 = local user
    
    return Container(
      color: Colors.black,
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: allUids.length,
        itemBuilder: (context, index) {
          final uid = allUids[index];
          final isLocal = uid == 0;

          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLocal ? Colors.blue : Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Video view
                  if (engine != null)
                    isLocal
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: engine!,
                              canvas: VideoCanvas(uid: 0),
                            ),
                          )
                        : AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: engine!,
                              canvas: VideoCanvas(uid: uid),
                              connection: RtcConnection(channelId: ''),
                            ),
                          )
                  else
                    Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  
                  // User label
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isLocal ? 'You' : 'User $uid',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}