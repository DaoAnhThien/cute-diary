import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const CuteDiaryApp());
}

class CuteDiaryApp extends StatelessWidget {
  const CuteDiaryApp({super.key});

  // HÀM TỰ ĐỘNG XÁC ĐỊNH MÀU NỀN THEO BUỔI TRONG NGÀY
  Color _getDynamicBackgroundColor() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return const Color(0xFFFFF0F5); // Sáng: Hồng bình minh dịu ngọt
    } else if (hour >= 11 && hour < 14) {
      return const Color(0xFFFFF8E7); // Trưa: Vàng kem ấm áp
    } else if (hour >= 14 && hour < 18) {
      return const Color(0xFFFFF0E6); // Chiều: Cam hoàng hôn lãng mạn
    } else {
      return const Color(0xFF2D2B32); // Tối/Đêm: Tím than ấm cúng, dịu mắt
    }
  }

  // HÀM XÁC ĐỊNH MÀU CHỮ/GIAO DIỆN PHÙ HỢP VỚI NỀN TỐI HAY SÁNG
  bool _isDarkMode() {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 5; // Trở thành dark mode vào ban đêm
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getDynamicBackgroundColor();
    final isDark = _isDarkMode();

    return MaterialApp(
      title: 'Nhật Ký Của Bác Sĩ Nhỏ',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: bgColor, // Áp dụng màu nền theo giờ
        appBarTheme: AppBarTheme(
          backgroundColor: isDark ? const Color(0xFF3A3840) : Colors.pink[200],
          foregroundColor: isDark ? Colors.white : Colors.black87,
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _diaryEntries = [];
  List<Map<String, dynamic>> _gardenFlowers = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ================= DATASET HỘP THƯ TƯƠNG LAI =================
  // Bạn có thể tùy chỉnh ngày mở (openDate theo định dạng YYYY-MM-DD) và nội dung ở đây
  final List<Map<String, dynamic>> _futureLetters = [
    {
      'title': 'Gửi bé yêu ngày trực lâm sàng đầu tiên ❤️',
      'content': 'Em yêu của anh ơi,\n\nHôm nay chắc là một ngày vô cùng vất vả với một bác sĩ tập sự đúng không nào? Lần đầu đứng trước bệnh nhân, lần đầu đối diện với áp lực bệnh viện chắc chắn sẽ có lúc em cảm thấy ngộp thở và mệt mỏi.\n\nNhưng đừng quên ở nhà luôn có anh chờ em nhé. Hãy hít một thật sâu, uống một ngụm nước ấm và tự thưởng cho mình một nụ cười nha. Em đã làm rất, rất tốt rồi cô bác sĩ nhỏ của anh!\n\nThương và ôm em thật chặt! ❤️',
      'openDate': '2026-11-11', // Ngày mở (Năm-Tháng-Ngày)
      'isOpened': false,
    },
    {
      'title': 'Gửi cô bác sĩ vào một ngày mưa gió 🌧️',
      'content': 'Bé ơi, ngoài trời đang mưa hay là trong lòng em đang có nhiều suy nghĩ bộn bề? Dù thế nào đi nữa, hãy nhớ rằng áp lực công việc chỉ là tạm thời, còn sức khỏe và nụ cười của em là quan trọng nhất.\n\nĐừng bắt bản thân phải gồng gánh mọi thứ một mình nhé. Cứ mệt quá thì dựa vào vai anh. Anh luôn ở đây sẵn sàng lắng nghe mọi câu chuyện trực đêm của em.\n\nCố lên nhé, cô gái kiên cường của anh! 🌸',
      'openDate': '2026-11-15', 
      'isOpened': false,
    },
    {
      'title': 'Kỷ niệm chặng đường chúng mình bên nhau 💍',
      'content': 'Thế là chúng mình lại cùng nhau đi qua thêm một cột mốc nữa rồi. Cảm ơn em vì đã luôn kiên nhẫn, dịu dàng và cùng anh vượt qua mọi thăng trầm trong cuộc sống.\n\nCông việc ngành y bận rộn khiến quỹ thời gian của chúng mình ít đi, nhưng anh biết tình cảm em dành cho anh và anh dành cho em chưa bao giờ phai nhạt.\n\nMãi yêu thương và đồng hành cùng nhau trên mọi chặng đường tương lai em nhé! Chúc tình yêu của chúng ta mãi ngọt ngào như ngày đầu tiên. 💖',
      'openDate': '2026-12-31', 
      'isOpened': false,
    },
  ];

  final List<Map<String, dynamic>> _reactions = [
    {'audio': 'thuong_qua.mp3', 'image': 'thuong_qua.jpg'},
    {'audio': 'gioi_qua.mp3', 'image': 'gioi_qua.png'},
    {'audio': 'om_mot_cai.mp3', 'image': 'om_mot_cai.jpg'},
  ];

  final List<Map<String, dynamic>> _moods = [
    {'id': 'vui', 'emoji': '😄', 'name': 'Vui vẻ', 'color': Colors.orange},
    {'id': 'hanh_phuc', 'emoji': '🥰', 'name': 'Hạnh phúc', 'color': Colors.pink},
    {'id': 'nho', 'emoji': '🥺', 'name': 'Nhớ nhung', 'color': Colors.purple},
    {'id': 'met', 'emoji': '😫', 'name': 'Mệt mỏi', 'color': Colors.grey},
    {'id': 'buon', 'emoji': '😢', 'name': 'Buồn', 'color': Colors.blue},
    {'id': 'biet_on', 'emoji': '🙏', 'name': 'Biết ơn', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _loadDiaryData();
    _loadLetterStatus();
    _loadGardenData();
  }

  Future<void> _loadDiaryData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? diaryData = prefs.getString('diary_data');
    if (diaryData != null) {
      final List<dynamic> decodedDiary = jsonDecode(diaryData);
      if (!mounted) return;
      setState(() {
        _diaryEntries = decodedDiary
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    }
  }

  // ================= DỮ LIỆU KHU VƯỜN PIXEL =================
  Future<void> _loadGardenData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gardenData = prefs.getString('garden_data');
    if (gardenData == null) return;

    try {
      final List<dynamic> decodedGarden = jsonDecode(gardenData);
      if (!mounted) return;
      setState(() {
        _gardenFlowers = decodedGarden
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu khu vườn: $e');
    }
  }

  Future<void> _updateGarden(List<Map<String, dynamic>> flowers) async {
    final updatedFlowers = flowers
        .map((flower) => Map<String, dynamic>.from(flower))
        .toList();
    if (!mounted) return;

    setState(() {
      _gardenFlowers = updatedFlowers;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('garden_data', jsonEncode(updatedFlowers));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Tải trạng thái đã đọc của các lá thư từ bộ nhớ máy
  Future<void> _loadLetterStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _futureLetters.length; i++) {
        bool? opened = prefs.getBool('letter_opened_$i');
        if (opened != null) {
          _futureLetters[i]['isOpened'] = opened;
        }
      }
    });
    _checkForSurpriseLetters();
  }

  void _checkForSurpriseLetters() {
    final now = DateTime.now();
    bool hasUnreadSurprise = false;

    for (var letter in _futureLetters) {
      final openDate = DateTime.parse(letter['openDate']);
      if (!now.isBefore(DateTime(openDate.year, openDate.month, openDate.day)) && letter['isOpened'] == false) {
        hasUnreadSurprise = true;
        break;
      }
    }

    if (hasUnreadSurprise) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSurpriseNotification();
      });
    }
  }

  void _showSurpriseNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.pink[50],
        title: const Text('Bíp bíp! 📬', textAlign: TextAlign.center, style: TextStyle(color: Colors.pink)),
        content: const Text(
          'Có một lá thư từ quá khứ đang chờ em.\nHãy vào Hộp Thư để xem nhé! ❤️',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[300]),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
              child: const Text('Đi xem ngay!', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _saveDiaryData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('diary_data', jsonEncode(_diaryEntries));
  }

  void _addDiaryEntry(Map<String, dynamic> newEntry) {
    setState(() => _diaryEntries.insert(0, newEntry));
    _saveDiaryData();
    _showRandomReaction();
  }

  Future<void> _markLetterAsOpened(int index) async {
    setState(() {
      _futureLetters[index]['isOpened'] = true;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('letter_opened_$index', true);
  }

  void _showRandomReaction() async {
    if (_reactions.isEmpty) return;
    final random = Random();
    final reaction = _reactions[random.nextInt(_reactions.length)];

    try {
      await _audioPlayer.play(AssetSource('audios/${reaction['audio']}'));
    } catch (e) {
      debugPrint("Lỗi phát audio: $e");
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/${reaction['image']}', fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              const Text('❤️', style: TextStyle(fontSize: 40)),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DiaryWritingTab(
        entries: _diaryEntries,
        moods: _moods,
        onSave: _addDiaryEntry,
      ),
      StatsAndCalendarTab(entries: _diaryEntries, moods: _moods),
      FutureMailboxTab(
        letters: _futureLetters,
        onOpenLetter: _markLetterAsOpened,
      ),
      PixelGardenTab(
        flowers: _gardenFlowers,
        onUpdateGarden: _updateGarden,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Nhật ký',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail),
            label: 'Hộp thư',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist),
            label: 'Khu vườn',
          ),
        ],
      ),
    );
  }
}

// ================= TAB 1: VIẾT NHẬT KÝ =================
class DiaryWritingTab extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> moods;
  final Function(Map<String, dynamic>) onSave;

  const DiaryWritingTab({super.key, required this.entries, required this.moods, required this.onSave});

  @override
  State<DiaryWritingTab> createState() => _DiaryWritingTabState();
}

class _DiaryWritingTabState extends State<DiaryWritingTab> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  String _selectedMoodId = 'vui';
  bool _isSpecialDay = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }

  void _handleSave() {
    if (_textController.text.isEmpty && _selectedImage == null) return;
    
    final newEntry = {
      'date': DateTime.now().toIso8601String(),
      'text': _textController.text,
      'imagePath': _selectedImage?.path ?? '',
      'moodId': _selectedMoodId,
      'isSpecial': _isSpecialDay,
    };

    widget.onSave(newEntry);

    setState(() {
      _textController.clear();
      _selectedImage = null;
      _isSpecialDay = false;
      _selectedMoodId = 'vui';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi thành công! ❤️'), backgroundColor: Colors.pinkAccent),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hôm nay bé sao rồi? 🌸'), backgroundColor: Colors.pink[200], elevation: 0),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.1), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tâm trạng của bé:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.moods.map((mood) {
                      final bool isSelected = _selectedMoodId == mood['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMoodId = mood['id']),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? mood['color'].withValues(alpha: 0.2) : Colors.transparent,
                            border: Border.all(color: isSelected ? mood['color'] : Colors.grey.withValues(alpha: 0.3)),
                            shape: BoxShape.circle,
                          ),
                          child: Text(mood['emoji'], style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                TextField(
                  controller: _textController, maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Kể anh nghe...', border: InputBorder.none),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.photo_library, color: Colors.pinkAccent), onPressed: _pickImage),
                        IconButton(
                          icon: Icon(
                            _isSpecialDay ? Icons.star : Icons.star_border,
                            color: _isSpecialDay ? Colors.amber : Colors.grey,
                            size: 28,
                          ),
                          tooltip: 'Đánh dấu ngày đặc biệt',
                          onPressed: () => setState(() => _isSpecialDay = !_isSpecialDay),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[300], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      onPressed: _handleSave,
                      child: const Text('Gửi 💌', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_selectedImage!, height: 100, width: double.infinity, fit: BoxFit.cover),
                    ),
                  )
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: widget.entries.length,
              itemBuilder: (context, index) {
                final entry = widget.entries[index];
                final date = DateTime.parse(entry['date']);
                final bool hasValidImage = entry['imagePath'] != '' && File(entry['imagePath']).existsSync();
                
                final mood = widget.moods.firstWhere((m) => m['id'] == (entry['moodId'] ?? 'vui'), orElse: () => widget.moods[0]);
                final bool isSpecial = entry['isSpecial'] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(mood['emoji'], style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                            if (isSpecial) const Icon(Icons.star, color: Colors.amber, size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(entry['text'], style: const TextStyle(fontSize: 16)),
                        if (hasValidImage)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(File(entry['imagePath'])),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================= TAB 2: THỐNG KÊ & LỊCH =================
class StatsAndCalendarTab extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final List<Map<String, dynamic>> moods;

  const StatsAndCalendarTab({super.key, required this.entries, required this.moods});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    Map<String, int> moodCounts = {};
    for (var m in moods) { moodCounts[m['id']] = 0; }
    
    List<Map<String, dynamic>> specialDays = [];

    for (var entry in entries) {
      final date = DateTime.parse(entry['date']);
      if (date.month == now.month && date.year == now.year) {
        String mId = entry['moodId'] ?? 'vui';
        if (moodCounts.containsKey(mId)) {
          moodCounts[mId] = (moodCounts[mId] ?? 0) + 1;
        }
      }
      if (entry['isSpecial'] == true) {
        specialDays.add(entry);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Góc Nhìn Của Bé 📊'), backgroundColor: Colors.pink[200], elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tâm trạng tháng này', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
            const SizedBox(height: 10),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: moods.map((m) {
                  int count = moodCounts[m['id']] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: m['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        Text(m['emoji'], style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: m['color'])),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Lịch cảm xúc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.1), blurRadius: 10)]),
              child: _buildSimpleCalendar(now),
            ),
            
            const SizedBox(height: 24),
            const Text('Những ngày đặc biệt ⭐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
            const SizedBox(height: 10),
            if (specialDays.isEmpty)
              const Text('Chưa có ngày đặc biệt nào được đánh dấu.', style: TextStyle(color: Colors.grey))
            else
              ...specialDays.map((entry) {
                final date = DateTime.parse(entry['date']);
                final mood = moods.firstWhere((m) => m['id'] == (entry['moodId'] ?? 'vui'), orElse: () => moods[0]);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.amber[50],
                  child: ListTile(
                    leading: Text(mood['emoji'], style: const TextStyle(fontSize: 24)),
                    title: Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(entry['text'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleCalendar(DateTime month) {
    int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    DateTime firstDay = DateTime(month.year, month.month, 1);
    int startWeekday = firstDay.weekday;

    List<Widget> dayWidgets = [];
    
    final List<String> weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    for (var day in weekDays) {
      dayWidgets.add(Center(child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))));
    }

    for (int i = 1; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      Map<String, dynamic>? entryOfDay;
      for (var e in entries) {
        var edate = DateTime.parse(e['date']);
        if (edate.year == month.year && edate.month == month.month && edate.day == d) {
          entryOfDay = e;
          break;
        }
      }

      Color bgColor = Colors.transparent;
      String emoji = '';
      if (entryOfDay != null) {
        final mood = moods.firstWhere((m) => m['id'] == (entryOfDay!['moodId'] ?? 'vui'));
        bgColor = mood['color'].withValues(alpha: 0.3);
        emoji = mood['emoji'];
      }

      dayWidgets.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('$d', style: TextStyle(color: bgColor == Colors.transparent ? Colors.black87 : Colors.black, fontWeight: bgColor != Colors.transparent ? FontWeight.bold : FontWeight.normal)),
              if (emoji.isNotEmpty)
                Positioned(bottom: 2, right: 2, child: Text(emoji, style: const TextStyle(fontSize: 10))),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }
}

// ================= TAB 3: HỘP THƯ TƯƠNG LAI (DỮ LIỆU CỐ ĐỊNH) =================
class FutureMailboxTab extends StatelessWidget {
  final List<Map<String, dynamic>> letters;
  final Function(int) onOpenLetter;

  const FutureMailboxTab({super.key, required this.letters, required this.onOpenLetter});

  // Hiển thị Popup đọc thư: Có thể lướt lên lướt xuống, không giới hạn thời gian, có nút X tắt
  void _showLetterDetail(BuildContext context, int index, Map<String, dynamic> letter) {
    onOpenLetter(index); // Đánh dấu đã đọc

    showDialog(
      context: context,
      barrierDismissible: true, // Cho phép bấm ra ngoài hoặc bấm dấu X để tắt
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 500), // Giới hạn chiều cao popup để có thể lướt nội dung dài
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh tiêu đề và Nút X đóng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      letter['title'], 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink[800]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context), // Nút X tắt popup
                    tooltip: 'Đóng',
                  ),
                ],
              ),
              const Divider(),
              // Nội dung thư có thể lướt lên lướt xuống thoải mái (Không giới hạn thời gian)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      letter['content'], 
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cất lại vào hộp 💌', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hộp Thư Tương Lai 💌'),
        backgroundColor: Colors.pink[200],
        elevation: 0,
      ),
      body: letters.isEmpty
        ? Center(child: Text('Chưa có lá thư nào ở đây cả.', style: TextStyle(color: Colors.grey[500])))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: letters.length,
            itemBuilder: (context, index) {
              final letter = letters[index];
              final openDate = DateTime.parse(letter['openDate']);
              
              // Kiểm tra xem đã đến ngày mở thư chưa
              final isReady = now.isAfter(openDate) || 
                              (now.year == openDate.year && now.month == openDate.month && now.day == openDate.day);
              
              if (!isReady) {
                // TRẠNG THÁI CHƯA ĐẾN NGÀY (BỊ KHÓA)
                return Card(
                  color: Colors.grey[200],
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(Icons.lock, color: Colors.grey, size: 30),
                    title: const Text('Lá thư được niêm phong', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    subtitle: Text('Sẽ mở vào ngày: ${openDate.day}/${openDate.month}/${openDate.year}'),
                    trailing: const Icon(Icons.hourglass_empty, color: Colors.grey),
                  ),
                );
              } else {
                // TRẠNG THÁI ĐÃ SẴN SÀNG ĐỂ MỞ
                final isOpened = letter['isOpened'] ?? false;
                return Card(
                  color: isOpened ? Colors.white : Colors.pink[50],
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isOpened ? 1 : 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    onTap: () => _showLetterDetail(context, index, letter),
                    leading: Icon(
                      isOpened ? Icons.drafts : Icons.mark_email_unread, 
                      color: isOpened ? Colors.pink[200] : Colors.pink, 
                      size: 30
                    ),
                    title: Text(letter['title'], style: TextStyle(fontWeight: FontWeight.bold, color: isOpened ? Colors.black87 : Colors.pink[800])),
                    subtitle: Text(isOpened ? 'Đã đọc (Nhấn để xem lại)' : 'Nhấn để mở ngay! 💌'),
                    trailing: isOpened ? null : const Icon(Icons.favorite, color: Colors.pinkAccent),
                  ),
                );
              }
            },
          ),
    );
  }
}
// ================= TAB 4: KHU VƯỜN PIXEL =================
class PixelGardenTab extends StatefulWidget {
  final List<Map<String, dynamic>> flowers;
  final Function(List<Map<String, dynamic>>) onUpdateGarden;

  const PixelGardenTab({
    super.key,
    required this.flowers,
    required this.onUpdateGarden,
  });

  @override
  State<PixelGardenTab> createState() => _PixelGardenTabState();
}

class _PixelGardenTabState extends State<PixelGardenTab> {
  int _missingDaysCount = 0;
  final List<File> _pendingPhotos = [];
  bool _milestoneDialogShown = false;

  @override
  void initState() {
    super.initState();
    _checkGardenStatus();
  }

  @override
  void didUpdateWidget(covariant PixelGardenTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flowers.length != widget.flowers.length) {
      _checkGardenStatus();
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _checkGardenStatus() {
    if (widget.flowers.isEmpty) {
      final todayString = _formatDate(DateTime.now());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.flowers.isNotEmpty) return;
        widget.onUpdateGarden([{'date': todayString, 'imagePath': ''}]);
      });
      return;
    }

    try {
      final lastDate = DateTime.parse(widget.flowers.last['date'].toString());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final difference = today.difference(lastDay).inDays;

      if (difference > 1) {
        if (mounted) setState(() => _missingDaysCount = difference - 1);
      } else {
        if (mounted && _missingDaysCount != 0) {
          setState(() => _missingDaysCount = 0);
        }
        if (difference == 1) {
          final todayString = _formatDate(now);
          if (!widget.flowers.any((flower) => flower['date'] == todayString)) {
            widget.onUpdateGarden([
              ...widget.flowers,
              {'date': todayString, 'imagePath': ''},
            ]);
          }
        }
      }
    } catch (_) {
      // Dữ liệu ngày cũ không hợp lệ: không làm ứng dụng bị dừng.
    }
  }

  Future<void> _pickCatchUpPhoto(int index) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() {
      while (_pendingPhotos.length <= index) {
        _pendingPhotos.add(File(''));
      }
      _pendingPhotos[index] = File(picked.path);
    });
  }

  void _submitCatchUpPhotos() {
    if (_pendingPhotos.length < _missingDaysCount ||
        _pendingPhotos.take(_missingDaysCount).any((file) => file.path.isEmpty)) {
      return;
    }

    final now = DateTime.now();
    final updated = List<Map<String, dynamic>>.from(widget.flowers);
    for (int i = 1; i <= _missingDaysCount; i++) {
      final date = now.subtract(Duration(days: _missingDaysCount - i + 1));
      updated.add({
        'date': _formatDate(date),
        'imagePath': _pendingPhotos[i - 1].path,
      });
    }
    final todayString = _formatDate(now);
    if (!updated.any((flower) => flower['date'] == todayString)) {
      updated.add({'date': todayString, 'imagePath': ''});
    }
    updated.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
    widget.onUpdateGarden(updated);
    setState(() {
      _missingDaysCount = 0;
      _pendingPhotos.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Khu vườn đã được chăm sóc trở lại! 🌱'),
        backgroundColor: Color(0xFF477B52),
      ),
    );
  }

  void _showFlowerDetail(Map<String, dynamic> flower, int index) {
    final imagePath = (flower['imagePath'] ?? '').toString();
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9ED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Bông hoa thứ ${index + 1} 🌼',
          style: const TextStyle(color: Color(0xFF477B52), fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ngày vun trồng: ${flower['date'] ?? 'Chưa rõ'}'),
            const SizedBox(height: 12),
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(imagePath), height: 190, width: double.infinity, fit: BoxFit.cover),
              )
            else
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Bông hoa này đang lưu giữ một ngày bình yên trong khu vườn của hai bạn.'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showHusbandReturnedDialog() {
    if (_milestoneDialogShown || !mounted) return;
    _milestoneDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFFFFF4F5),
          title: const Text('🎉 ĐÃ ĐỦ 730 NGÀY! 🎉', textAlign: TextAlign.center),
          content: const Text(
            'Chặng đường vun trồng khu vườn đã hoàn thành. Cảm ơn hai bạn vì đã cùng nhau lưu giữ từng kỷ niệm! ❤️',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hoàn thành'),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalFlowers = widget.flowers.length;
    const milestones = [7, 30, 100, 200, 300, 400, 500, 600, 700, 730];
    final nextMilestone = milestones.firstWhere((value) => totalFlowers < value, orElse: () => 730);
    final progress = (totalFlowers / nextMilestone).clamp(0.0, 1.0).toDouble();

    if (totalFlowers >= 730) _showHusbandReturnedDialog();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EB),
      appBar: AppBar(
        title: const Text('Khu vườn của chúng mình 🌷'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFE6E8),
        foregroundColor: const Color(0xFF49694B),
        elevation: 0,
      ),
      body: _missingDaysCount > 0 ? _buildCatchUpView() : _buildGardenView(
        totalFlowers: totalFlowers,
        nextMilestone: nextMilestone,
        progress: progress,
      ),
    );
  }

  Widget _buildCatchUpView() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(Icons.local_florist, size: 54, color: Color(0xFFE58BA5)),
          const SizedBox(height: 10),
          Text(
            'Khu vườn đang nhớ bạn mất rồi!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF477B52)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('Bạn đã vắng mặt $_missingDaysCount ngày. Hãy thêm ảnh kỷ niệm cho những ngày đó nhé.'),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              itemCount: _missingDaysCount,
              itemBuilder: (context, index) {
                final hasPhoto = index < _pendingPhotos.length && _pendingPhotos[index].path.isNotEmpty;
                return Card(
                  color: const Color(0xFFFFFDF7),
                  child: ListTile(
                    leading: Icon(Icons.photo_library, color: hasPhoto ? Colors.green : Colors.pink),
                    title: Text('Kỷ niệm ngày ${index + 1}'),
                    trailing: TextButton(
                      onPressed: () => _pickCatchUpPhoto(index),
                      child: Text(hasPhoto ? 'Đã chọn ✓' : 'Chọn ảnh'),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pendingPhotos.length == _missingDaysCount &&
                      _pendingPhotos.every((file) => file.path.isNotEmpty)
                  ? _submitCatchUpPhotos
                  : null,
              icon: const Icon(Icons.spa),
              label: const Text('Chăm sóc lại khu vườn'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenView({
    required int totalFlowers,
    required int nextMilestone,
    required double progress,
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF2D8C9)),
          ),
          child: Column(
            children: [
              Text(
                '$totalFlowers bông hoa đã được vun trồng',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF477B52), fontSize: 16),
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFF4E4D7),
                  color: const Color(0xFF78A86F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mục tiêu tiếp theo: $nextMilestone ngày',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8878)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CustomPaint(
                painter: PixelGardenGroundPainter(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF53646A), width: 7),
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    itemCount: widget.flowers.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 4,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final flower = widget.flowers[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showFlowerDetail(flower, index),
                        child: CustomPaint(
                          painter: PixelFlowerPainter(variant: index % 6),
                          child: const SizedBox.expand(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 2, 12, 12),
          child: Text(
            'Chạm vào một bông hoa để mở lại kỷ niệm của ngày hôm đó ✨',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7C8875), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Nền cỏ dạng pixel cùng hàng rào đá gợi lại hình mẫu người dùng gửi.
class PixelGardenGroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grass = Paint()..color = const Color(0xFF69B99A);
    canvas.drawRect(Offset.zero & size, grass);
    final random = Random(21);
    final colors = [
      const Color(0xFF83C9A5),
      const Color(0xFF4FA783),
      const Color(0xFF9BD3AD),
      const Color(0xFF5EAE91),
    ];
    for (int i = 0; i < (size.width * size.height / 100).round(); i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final paint = Paint()..color = colors[random.nextInt(colors.length)];
      canvas.drawRect(Rect.fromLTWH(x, y, 3.5, 3.5), paint);
    }

    final stone = Paint()..color = const Color(0xFF59666D);
    final stoneLight = Paint()..color = const Color(0xFFA7B2B5);
    const block = 17.0;
    // Hàng rào trên và dưới.
    for (double x = 0; x < size.width; x += block * 1.5) {
      canvas.drawRect(Rect.fromLTWH(x, 0, block, 9), stone);
      canvas.drawRect(Rect.fromLTWH(x + 3, 9, block - 6, 9), stoneLight);
      canvas.drawRect(Rect.fromLTWH(x, size.height - 9, block, 9), stone);
      canvas.drawRect(Rect.fromLTWH(x + 3, size.height - 18, block - 6, 9), stoneLight);
    }
    // Hai cạnh bên.
    for (double y = 10; y < size.height - 10; y += block * 1.5) {
      canvas.drawRect(Rect.fromLTWH(0, y, 9, block), stone);
      canvas.drawRect(Rect.fromLTWH(9, y + 3, 8, block - 6), stoneLight);
      canvas.drawRect(Rect.fromLTWH(size.width - 9, y, 9, block), stone);
      canvas.drawRect(Rect.fromLTWH(size.width - 17, y + 3, 8, block - 6), stoneLight);
    }
  }

  @override
  bool shouldRepaint(covariant PixelGardenGroundPainter oldDelegate) => false;
}

/// Vẽ từng bông hoa bằng các khối màu vuông, không phụ thuộc emoji hay font máy.
class PixelFlowerPainter extends CustomPainter {
  final int variant;
  const PixelFlowerPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width / 56, size.height / 68);
    final left = (size.width - 56 * scale) / 2;
    final top = (size.height - 68 * scale) / 2;
    canvas.save();
    canvas.translate(left, top);
    canvas.scale(scale);

    final petalColors = [
      const Color(0xFFF5C64F),
      const Color(0xFFEA79B0),
      const Color(0xFF8AA9E8),
      const Color(0xFFF1A94D),
      const Color(0xFFE87FA4),
      const Color(0xFF9B9DE5),
    ];
    final petal = Paint()..color = petalColors[variant % petalColors.length];
    final white = Paint()..color = const Color(0xFFFFF8E8);
    final center = Paint()..color = const Color(0xFFF5D66A);
    final leaf = Paint()..color = const Color(0xFF287B3D);
    final leafLight = Paint()..color = const Color(0xFF55A34D);
    final stem = Paint()..color = const Color(0xFF367B3D);

    // Thân và lá.
    canvas.drawRect(const Rect.fromLTWH(27, 31, 4, 27), stem);
    canvas.drawRect(const Rect.fromLTWH(13, 43, 15, 6), leaf);
    canvas.drawRect(const Rect.fromLTWH(8, 39, 10, 6), leafLight);
    canvas.drawRect(const Rect.fromLTWH(29, 47, 15, 6), leaf);
    canvas.drawRect(const Rect.fromLTWH(39, 43, 9, 6), leafLight);
    canvas.drawRect(const Rect.fromLTWH(21, 55, 17, 5), leaf);

    // Cụm hoa chính và bông nhỏ bên cạnh.
    canvas.drawRect(const Rect.fromLTWH(17, 9, 10, 10), petal);
    canvas.drawRect(const Rect.fromLTWH(27, 3, 10, 10), petal);
    canvas.drawRect(const Rect.fromLTWH(37, 9, 10, 10), petal);
    canvas.drawRect(const Rect.fromLTWH(27, 19, 10, 9), petal);
    canvas.drawRect(const Rect.fromLTWH(27, 12, 10, 9), center);
    canvas.drawRect(const Rect.fromLTWH(4, 22, 8, 8), white);
    canvas.drawRect(const Rect.fromLTWH(12, 17, 8, 8), white);
    canvas.drawRect(const Rect.fromLTWH(12, 25, 8, 8), white);
    canvas.drawRect(const Rect.fromLTWH(20, 22, 8, 8), white);
    canvas.drawRect(const Rect.fromLTWH(12, 22, 8, 8), center);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PixelFlowerPainter oldDelegate) => oldDelegate.variant != variant;
}
