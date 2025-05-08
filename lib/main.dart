import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'models/data.dart';
import 'models/settings.dart';

const String removeAdsProductId = 'remove_ads';
const String bannerAdUnitId = 'ca-app-pub-6013595140756833/7290052213'; // Test Ad Unit ID

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize(); // Initialize Google Mobile Ads SDK
  final portfolioData = await _loadPortfolioData();
  final settings = await _loadSettings();
  final inAppPurchase = InAppPurchase.instance;
  await inAppPurchase.restorePurchases();
  runApp(MyPortfolioApp(
    initialPortfolioData: portfolioData,
    initialSettings: settings,
    inAppPurchase: inAppPurchase,
  ));
}

Future<PortfolioData> _loadPortfolioData() async {
  final prefs = await SharedPreferences.getInstance();
  final dataJson = prefs.getString('portfolio_data');
  if (dataJson != null) {
    return PortfolioData.fromJson(jsonDecode(dataJson));
  }
  return PortfolioData();
}

Future<Settings> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final dataJson = prefs.getString('settings_data');
  if (dataJson != null) {
    return Settings.fromJson(jsonDecode(dataJson));
  }
  return Settings();
}

class MyPortfolioApp extends StatefulWidget {
  final PortfolioData initialPortfolioData;
  final Settings initialSettings;
  final InAppPurchase inAppPurchase;

  const MyPortfolioApp({
    super.key,
    required this.initialPortfolioData,
    required this.initialSettings,
    required this.inAppPurchase,
  });

  @override
  _MyPortfolioAppState createState() => _MyPortfolioAppState();
}

class _MyPortfolioAppState extends State<MyPortfolioApp> {
  late PortfolioData portfolioData;
  late Settings settings;
  int _selectedIndex = 0;
  late final InAppPurchase _inAppPurchase;
  bool _isAdsRemoved = false;

  @override
  void initState() {
    super.initState();
    portfolioData = widget.initialPortfolioData;
    settings = widget.initialSettings;
    _inAppPurchase = widget.inAppPurchase;
    _loadPurchaseStatus();
    _inAppPurchase.purchaseStream.listen((purchaseDetails) {
      _handlePurchaseUpdate(purchaseDetails);
    }, onError: (error) {
      // Handle errors
    });
  }

  Future<void> _loadPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdsRemoved = prefs.getBool('ads_removed') ?? false;
    });
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetails) async {
    for (var purchase in purchaseDetails) {
      if (purchase.productID == removeAdsProductId && purchase.status == PurchaseStatus.purchased) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('ads_removed', true);
        setState(() {
          _isAdsRemoved = true;
        });
      }
    }
  }

  Future<void> _buyRemoveAds() async {
    final product = await _inAppPurchase.queryProductDetails({removeAdsProductId});
    if (product.notFoundIDs.isEmpty) { // Changed from notFoundProductIDs to notFoundIDs
      final purchaseParam = PurchaseParam(productDetails: product.productDetails.first);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  void updatePortfolioData(PortfolioData newData) {
    setState(() {
      portfolioData = newData;
    });
  }

  void updateSettings(Settings newSettings) {
    setState(() {
      settings = newSettings;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return PortfolioHomeScreen(
          portfolioData: portfolioData,
          onUpdate: updatePortfolioData,
          themeName: settings.themeName,
          isDarkMode: settings.isDarkMode,
          isAdsRemoved: _isAdsRemoved,
        );
      case 1:
        return EditProfileScreen(
          portfolioData: portfolioData,
          onUpdate: updatePortfolioData,
        );
      case 2:
        return SettingsScreen(
          settings: settings,
          onUpdate: updateSettings,
          onRemoveAds: _buyRemoveAds,
          isAdsRemoved: _isAdsRemoved,
        );
      default:
        return PortfolioHomeScreen(
          portfolioData: portfolioData,
          onUpdate: updatePortfolioData,
          themeName: settings.themeName,
          isDarkMode: settings.isDarkMode,
          isAdsRemoved: _isAdsRemoved,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Portfolio',
      theme: settings.isDarkMode
          ? ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyMedium: TextStyle(fontSize: settings.fontSize),
          titleLarge: TextStyle(fontSize: settings.fontSize * 1.5),
          titleMedium: TextStyle(fontSize: settings.fontSize * 1.25),
        ),
      )
          : ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        textTheme: ThemeData.light().textTheme.copyWith(
          bodyMedium: TextStyle(fontSize: settings.fontSize),
          titleLarge: TextStyle(fontSize: settings.fontSize * 1.5),
          titleMedium: TextStyle(fontSize: settings.fontSize * 1.25),
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('My Portfolio'),
          ),
          body: _getCurrentScreen(),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.edit),
                    label: 'Edit',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                onTap: _onItemTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PortfolioHomeScreen extends StatefulWidget {
  final PortfolioData portfolioData;
  final Function(PortfolioData) onUpdate;
  final String themeName;
  final bool isDarkMode;
  final bool isAdsRemoved;

  const PortfolioHomeScreen({
    super.key,
    required this.portfolioData,
    required this.onUpdate,
    required this.themeName,
    required this.isDarkMode,
    required this.isAdsRemoved,
  });

  @override
  _PortfolioHomeScreenState createState() => _PortfolioHomeScreenState();
}

class _PortfolioHomeScreenState extends State<PortfolioHomeScreen> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isAdsRemoved) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getThemeStyles() {
    switch (widget.themeName) {
      case 'theme1':
        return {
          'backgroundGradient': LinearGradient(
            colors: widget.isDarkMode
                ? [Colors.purple[800]!, Colors.purple[900]!]
                : [Colors.purple[300]!, Colors.purple[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'textColor': widget.isDarkMode ? Colors.white : Colors.white,
          'accentColor': widget.isDarkMode ? Colors.amber[300]! : Colors.amber,
          'cardColor': widget.isDarkMode
              ? Colors.purple[900]!
              : Colors.purple[800]!,
        };
      case 'theme2':
        return {
          'backgroundGradient': LinearGradient(
            colors: widget.isDarkMode
                ? [Colors.teal[800]!, Colors.teal[900]!]
                : [Colors.teal[300]!, Colors.teal[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'textColor': widget.isDarkMode ? Colors.white : Colors.white,
          'accentColor': widget.isDarkMode ? Colors.orange[300]! : Colors.orange,
          'cardColor': widget.isDarkMode
              ? Colors.teal[900]!
              : Colors.teal[800]!,
        };
      case 'theme3':
        return {
          'backgroundGradient': LinearGradient(
            colors: widget.isDarkMode
                ? [Colors.red[800]!, Colors.red[900]!]
                : [Colors.orange[300]!, Colors.red[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'textColor': widget.isDarkMode ? Colors.white : Colors.white,
          'accentColor': widget.isDarkMode ? Colors.purple[300]! : Colors.purple,
          'cardColor': widget.isDarkMode
              ? Colors.red[900]!
              : Colors.red[800]!,
        };
      default:
        return {
          'backgroundGradient': LinearGradient(
            colors: widget.isDarkMode
                ? [Colors.purple[800]!, Colors.purple[900]!]
                : [Colors.purple[300]!, Colors.purple[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'textColor': widget.isDarkMode ? Colors.white : Colors.white,
          'accentColor': widget.isDarkMode ? Colors.amber[300]! : Colors.amber,
          'cardColor': widget.isDarkMode
              ? Colors.purple[900]!
              : Colors.purple[800]!,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeStyles = _getThemeStyles();
    return Container(
      decoration: BoxDecoration(
        gradient: themeStyles['backgroundGradient'],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileSection(
                      portfolioData: widget.portfolioData,
                      accentColor: themeStyles['accentColor'],
                    ),
                    const SizedBox(height: 20),
                    ShortBio(
                      portfolioData: widget.portfolioData,
                      textColor: themeStyles['textColor'],
                      cardColor: themeStyles['cardColor'],
                    ),
                    const SizedBox(height: 20),
                    ContactInfo(
                      portfolioData: widget.portfolioData,
                      textColor: themeStyles['textColor'],
                      cardColor: themeStyles['cardColor'],
                    ),
                    const SizedBox(height: 20),
                    SkillsList(
                      portfolioData: widget.portfolioData,
                      textColor: themeStyles['textColor'],
                      cardColor: themeStyles['cardColor'],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.isAdsRemoved && _isAdLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  final PortfolioData portfolioData;
  final Color accentColor;

  const ProfileSection({
    super.key,
    required this.portfolioData,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: accentColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: portfolioData.profileImagePath.startsWith('assets')
                ? const AssetImage('assets/images/profile.jpg')
                : FileImage(File(portfolioData.profileImagePath)) as ImageProvider,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                portfolioData.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                portfolioData.title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ShortBio extends StatelessWidget {
  final PortfolioData portfolioData;
  final Color textColor;
  final Color cardColor;

  const ShortBio({
    super.key,
    required this.portfolioData,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        portfolioData.bio,
        style: TextStyle(
          fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16,
          color: textColor,
        ),
      ),
    );
  }
}

class ContactInfo extends StatelessWidget {
  final PortfolioData portfolioData;
  final Color textColor;
  final Color cardColor;

  const ContactInfo({
    super.key,
    required this.portfolioData,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email: ${portfolioData.email}', style: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16, color: textColor)),
          Text('Phone: ${portfolioData.phone}', style: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16, color: textColor)),
          Text('LinkedIn: ${portfolioData.linkedin}', style: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16, color: textColor)),
        ],
      ),
    );
  }
}

class SkillsList extends StatelessWidget {
  final PortfolioData portfolioData;
  final Color textColor;
  final Color cardColor;

  const SkillsList({
    super.key,
    required this.portfolioData,
    required this.textColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills & Interests',
            style: TextStyle(fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: portfolioData.skills.map((skill) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('• $skill', style: TextStyle(fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16, color: textColor)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final PortfolioData portfolioData;
  final Function(PortfolioData) onUpdate;

  const EditProfileScreen({
    super.key,
    required this.portfolioData,
    required this.onUpdate,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _linkedinController;
  late TextEditingController _skillsController;
  late PortfolioData _updatedPortfolioData;

  @override
  void initState() {
    super.initState();
    _updatedPortfolioData = PortfolioData()
      ..name = widget.portfolioData.name
      ..title = widget.portfolioData.title
      ..bio = widget.portfolioData.bio
      ..email = widget.portfolioData.email
      ..phone = widget.portfolioData.phone
      ..linkedin = widget.portfolioData.linkedin
      ..skills = List.from(widget.portfolioData.skills)
      ..profileImagePath = widget.portfolioData.profileImagePath;
    _nameController = TextEditingController(text: widget.portfolioData.name);
    _titleController = TextEditingController(text: widget.portfolioData.title);
    _bioController = TextEditingController(text: widget.portfolioData.bio);
    _emailController = TextEditingController(text: widget.portfolioData.email);
    _phoneController = TextEditingController(text: widget.portfolioData.phone);
    _linkedinController = TextEditingController(text: widget.portfolioData.linkedin);
    _skillsController = TextEditingController(text: widget.portfolioData.skills.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    _updatedPortfolioData
      ..name = _nameController.text
      ..title = _titleController.text
      ..bio = _bioController.text
      ..email = _emailController.text
      ..phone = _phoneController.text
      ..linkedin = _linkedinController.text
      ..skills = _skillsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    await prefs.setString('portfolio_data', jsonEncode(_updatedPortfolioData.toJson()));
    widget.onUpdate(_updatedPortfolioData);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() {
        _updatedPortfolioData.profileImagePath = savedImage.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _updatedPortfolioData.profileImagePath.startsWith('assets')
                  ? const AssetImage('assets/images/profile.jpg')
                  : FileImage(File(_updatedPortfolioData.profileImagePath)) as ImageProvider,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Bio'),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _linkedinController,
            decoration: const InputDecoration(labelText: 'LinkedIn'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _skillsController,
            decoration: const InputDecoration(labelText: 'Skills (comma-separated)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveData,
            child: const Text('Save Profile'),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Settings settings;
  final Function(Settings) onUpdate;
  final VoidCallback onRemoveAds;
  final bool isAdsRemoved;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onUpdate,
    required this.onRemoveAds,
    required this.isAdsRemoved,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  late double _fontSize;
  late String _themeName;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.settings.isDarkMode;
    _fontSize = widget.settings.fontSize;
    _themeName = widget.settings.themeName;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedSettings = Settings()
      ..isDarkMode = _isDarkMode
      ..fontSize = _fontSize
      ..themeName = _themeName;
    await prefs.setString('settings_data', jsonEncode(updatedSettings.toJson()));
    widget.onUpdate(updatedSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theme',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Home Page Theme',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: _themeName,
            isExpanded: true,
            items: const [
              DropdownMenuItem(
                value: 'theme1',
                child: Text('Purple Dream (Purple Gradient)'),
              ),
              DropdownMenuItem(
                value: 'theme2',
                child: Text('Ocean Breeze (Teal Gradient)'),
              ),
              DropdownMenuItem(
                value: 'theme3',
                child: Text('Sunset Glow (Orange-Red Gradient)'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _themeName = value!;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Font Size',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _fontSize,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            label: _fontSize.round().toString(),
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.isAdsRemoved ? null : widget.onRemoveAds,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isAdsRemoved ? Colors.grey : Colors.blue,
            ),
            child: Text(widget.isAdsRemoved ? 'Ads Removed' : 'Remove Ads (In-App Purchase)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}