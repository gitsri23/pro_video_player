import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:math' as math;

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

class _IOSLauncherState extends State<IOSLauncher> with SingleTickerProviderStateMixin {
  List<AppInfo> allApps = [];
  List<AppInfo> filteredApps = [];
  TextEditingController searchController = TextEditingController();
  
  // iOS 18 ఫీచర్స్ కోసం స్టేట్
  bool isEditingMode = false; // Jiggle Mode కోసం
  bool isTintedMode = false;  // డార్క్ టింట్ ఐకాన్స్ కోసం
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _loadApps();
    
    // ఐకాన్స్ ఊగడానికి యానిమేషన్ సెటప్
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  // యాప్స్ లోడ్ చేయడం (సిస్టమ్ యాప్స్ హైడ్ చేసి, ఐకాన్స్ తో సహా)
  Future<void> _loadApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);
    apps.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));
    setState(() {
      allApps = apps;
      filteredApps = apps;
    });
  }

  // స్పాట్‌లైట్ సెర్చ్ లాజిక్
  void _filterApps(String query) {
    setState(() {
      filteredApps = allApps
          .where((app) => app.name!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // యాప్ అన్‌ఇన్‌స్టాల్ చేయడానికి
  void _uninstallApp(String packageName) {
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.DELETE',
      data: 'package:$packageName',
    );
    intent.launch();
  }

  // డిఫాల్ట్ లాంచర్ సెట్టింగ్స్
  void _openDefaultLauncherSettings() {
    const intent = AndroidIntent(action: 'android.settings.HOME_SETTINGS');
    intent.launch();
  }

  // స్వైప్ డౌన్ కంట్రోల్ సెంటర్
  void _showControlCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildControlCenter(),
    );
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // వాల్‌పేపర్ లోడ్ అయ్యేలోపు బ్లాక్ స్క్రీన్
      body: GestureDetector(
        // స్క్రీన్ మీద ఎక్కడ నొక్కినా ఎడిటింగ్ మోడ్ ఆఫ్ అవుతుంది
        onTap: () {
          if (isEditingMode) {
            setState(() => isEditingMode = false);
            _wiggleController.stop();
          }
        },
        // పైనుంచి కిందికి స్వైప్ చేస్తే కంట్రోల్ సెంటర్ వస్తుంది
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _showControlCenter();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              // iOS 18 స్టాక్ వాల్‌పేపర్ లింక్ (దీనికి ఇంటర్నెట్ పర్మిషన్ కావాలి)
              image: NetworkImage("https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=1000&auto=format&fit=crop"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 50),
              _buildSearchBar(), // సెర్చ్ బార్
              Expanded(
                child: filteredApps.isEmpty 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 25,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: filteredApps.length,
                      itemBuilder: (context, index) {
                        AppInfo app = filteredApps[index];
                        return _buildAppIcon(app, index);
                      },
                    ),
              ),
              _buildDock(), // బాటమ్ డాక్
            ],
          ),
        ),
      ),
    );
  }

  // యాప్ ఐకాన్ డిజైన్ మరియు యానిమేషన్స్
  Widget _buildAppIcon(AppInfo app, int index) {
    double offset = (index % 2 == 0) ? 1.0 : -1.0;

    return GestureDetector(
      onTap: () {
        if (isEditingMode) return; // ఎడిట్ మోడ్‌లో యాప్ ఓపెన్ అవ్వదు
        InstalledApps.startApp(app.packageName!);
      },
      onLongPress: () {
        setState(() => isEditingMode = true); // లాంగ్ ప్రెస్ చేస్తే ఊగడం స్టార్ట్
        _wiggleController.repeat(reverse: true);
      },
      child: AnimatedBuilder(
        animation: _wiggleController,
        builder: (context, child) {
          double angle = isEditingMode ? math.sin(_wiggleController.value * math.pi * 2) * 0.05 * offset : 0.0;
          return Transform.rotate(angle: angle, child: child);
        },
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColorFiltered(
                    // టింటెడ్ మోడ్ అప్లై చేయడం
                    colorFilter: isTintedMode
                        ? ColorFilter.mode(Colors.blueAccent.withOpacity(0.6), BlendMode.srcATop)
                        : const ColorFilter.mode(Colors.transparent, BlendMode.clear),
                    child: app.icon != null 
                        ? Image.memory(app.icon!, width: 60, height: 60, fit: BoxFit.cover)
                        : Container(width: 60, height: 60, color: Colors.grey.shade800, child: const Icon(Icons.apps, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  app.name ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500, shadows: [Shadow(blurRadius: 3, color: Colors.black)]),
                ),
              ],
            ),
            // మైనస్ (-) గుర్తు (Uninstall Button)
            if (isEditingMode)
              GestureDetector(
                onTap: () => _uninstallApp(app.packageName!),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(Icons.remove, size: 14, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // గ్లాస్ ఎఫెక్ట్ సెర్చ్ బార్
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassmorphicContainer(
        width: double.infinity, height: 45, borderRadius: 12, blur: 10, alignment: Alignment.center, border: 1,
        linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
        borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)]),
        child: TextField(
          controller: searchController,
          onChanged: _filterApps,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Search apps...", hintStyle: TextStyle(color: Colors.white70), prefixIcon: Icon(Icons.search, color: Colors.white70), border: InputBorder.none, contentPadding: EdgeInsets.only(top: 10)),
        ),
      ),
    );
  }

  // బాటమ్ గ్లాస్ డాక్ (అప్‌డేటెడ్ క్లిక్ యాక్షన్స్ తో)
  Widget _buildDock() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25, left: 15, right: 15),
      child: GlassmorphicContainer(
        width: double.infinity, height: 90, borderRadius: 28, blur: 25, alignment: Alignment.center, border: 1.5,
        linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)]),
        borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.1)]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // డైలర్ ఓపెన్ చేయడానికి
            _dockIcon(Icons.phone, Colors.green, () => InstalledApps.startApp("com.android.contacts")),
            // మెసేజెస్ ఓపెన్ చేయడానికి
            _dockIcon(Icons.chat_bubble, Colors.blue, () => InstalledApps.startApp("com.google.android.apps.messaging")),
            // లాంచర్ సెట్టింగ్స్ కోసం
            _dockIcon(Icons.settings, Colors.grey.shade700, _openDefaultLauncherSettings),
            // క్రోమ్/బ్రౌజర్ కోసం
            _dockIcon(Icons.public, Colors.blueAccent, () => InstalledApps.startApp("com.android.chrome")),
          ],
        ),
      ),
    );
  }

  // డాక్ ఐకాన్ డిజైన్
  Widget _dockIcon(IconData icon, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: bgColor, 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

  // స్వైప్ డౌన్ కంట్రోల్ సెంటర్ డిజైన్
  Widget _buildControlCenter() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      margin: const EdgeInsets.all(15),
      child: GlassmorphicContainer(
        width: double.infinity, height: double.infinity, borderRadius: 30, blur: 20, alignment: Alignment.topCenter, border: 1,
        linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.black.withOpacity(0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.3), Colors.transparent]),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("Control Center", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ccButton(Icons.wifi, Colors.blue),
                  _ccButton(Icons.bluetooth, Colors.blue),
                  // కలర్ టింట్ మోడ్ టోగుల్ చేయడానికి ఇక్కడ కూడా ఆప్షన్ పెట్టాను
                  GestureDetector(
                    onTap: () {
                      setState(() => isTintedMode = !isTintedMode);
                      Navigator.pop(context); // మోడ్ మార్చాక క్లోజ్ అవుతుంది
                    },
                    child: _ccButton(isTintedMode ? Icons.palette : Icons.palette_outlined, isTintedMode ? Colors.deepPurple : Colors.grey),
                  ),
                  _ccButton(Icons.flashlight_on, Colors.white, iconColor: Colors.black),
                ],
              ),
              const SizedBox(height: 30),
              _ccSlider(Icons.brightness_high),
              const SizedBox(height: 15),
              _ccSlider(Icons.volume_up),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ccButton(IconData icon, Color bgColor, {Color iconColor = Colors.white}) {
    return Container(width: 60, height: 60, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: iconColor, size: 30));
  }

  Widget _ccSlider(IconData icon) {
    return Container(
      width: double.infinity, height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
      child: Row(children: [const SizedBox(width: 15), Icon(icon, color: Colors.white), const SizedBox(width: 10), Expanded(child: Container(margin: const EdgeInsets.only(right: 15), height: 8, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))))]),
    );
  }
}
