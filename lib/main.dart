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

  Future<void> _loadApps() async {
    List<AppInfo> installedApps = await InstalledApps.getInstalledApps();
    setState(() {
      apps = installedApps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(height: 60),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 25,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  AppInfo app = apps[index];
                  return GestureDetector(
                    onTap: () => InstalledApps.startApp(app.packageName!),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: app.icon != null 
                              ? Image.memory(app.icon!, width: 60, height: 60)
                              : const Icon(Icons.apps, size: 60, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          app.name ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildDock(),
          ],
        ),
      ),
    );
  }

  Widget _buildDock() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: GlassmorphicContainer(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 90,
        borderRadius: 30,
        blur: 15,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
        ),
        borderGradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.2)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _dockIcon(Icons.phone, Colors.green),
            _dockIcon(Icons.message, Colors.blue),
            _dockIcon(Icons.camera_alt, Colors.grey),
            _dockIcon(Icons.language, Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _dockIcon(IconData icon, Color color) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}
