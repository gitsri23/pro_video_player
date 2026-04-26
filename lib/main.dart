import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:glassmorphism/glassmorphism.dart';

void main() {
  runApp(const MaterialApp(
    home: IOSLauncher(),
    debugShowCheckedModeBanner: false,
  ));
}

class IOSLauncher extends StatefulWidget {
  const IOSLauncher({super.key});

  @override
  State<IOSLauncher> createState() => _IOSLauncherState();
}

class _IOSLauncherState extends State<IOSLauncher> {
  List<AppInfo> apps = [];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  // యాప్స్ మరియు ఐకాన్స్‌ను లోడ్ చేసే ఫంక్షన్
  Future<void> _loadApps() async {
    // false = సిస్టమ్ యాప్స్ కూడా కావాలి
    // true = యాప్ ఐకాన్స్ కూడా కచ్చితంగా కావాలి
    List<AppInfo> installedApps = await InstalledApps.getInstalledApps(false, true);
    
    // ఆల్ఫాబెటికల్ ఆర్డర్‌లో సార్ట్ చేయడం
    installedApps.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));

    setState(() {
      apps = installedApps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // వాల్‌పేపర్ లోడ్ అయ్యేలోపు బ్లాక్ స్క్రీన్
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage("https://images.wallpapersden.com/image/download/ios-18-stock-wallpaper_bWlsam6UmZqaraWkpJRmbmdlrWZlbWU.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 55), // స్టేటస్ బార్ స్పేస్
            Expanded(
              child: apps.isEmpty 
                ? const Center(child: CircularProgressIndicator(color: Colors.white)) // యాప్స్ లోడ్ అయ్యేలోపు యానిమేషన్
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 15,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      AppInfo app = apps[index];
                      return GestureDetector(
                        onTap: () => InstalledApps.startApp(app.packageName!),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // ఐకాన్ (Border Radius తో)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: app.icon != null 
                                  ? Image.memory(app.icon!, width: 55, height: 55, fit: BoxFit.cover)
                                  : Container(
                                      width: 55, height: 55, color: Colors.grey.withOpacity(0.5),
                                      child: const Icon(Icons.apps, color: Colors.white),
                                    ),
                            ),
                            const SizedBox(height: 5),
                            // యాప్ పేరు
                            Text(
                              app.name ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(blurRadius: 3, color: Colors.black87, offset: Offset(0, 1)) // టెక్స్ట్ క్లియర్ గా కనిపించడానికి షాడో
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
            _buildDock(), // కింద ఉండే డాక్
          ],
        ),
      ),
    );
  }

  // iOS గ్లాస్ డాక్ డిజైన్
  Widget _buildDock() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25, left: 15, right: 15),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 85,
        borderRadius: 25,
        blur: 15,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.05)],
        ),
        borderGradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.2)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _dockIcon(Icons.phone, Colors.green),
            _dockIcon(Icons.message, Colors.blue),
            _dockIcon(Icons.camera_alt, Colors.grey.shade300, iconColor: Colors.black87),
            _dockIcon(Icons.language, Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _dockIcon(IconData icon, Color bgColor, {Color iconColor = Colors.white}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}
