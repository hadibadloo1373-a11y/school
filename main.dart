import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MagicSchoolApp());
}

const pink = Color(0xFFFFE0EF);
const purple = Color(0xFFEDE3FF);
const lilac = Color(0xFF9A78C8);
const ink = Color(0xFF493B58);

class Student {
  Student({required this.id, required this.name, this.avatar = '👧', this.stars = 0, this.done = const []});
  final String id;
  String name;
  String avatar;
  int stars;
  List<int> done;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar': avatar, 'stars': stars, 'done': done};
  factory Student.fromJson(Map<String, dynamic> j) => Student(
    id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
    name: j['name'] as String? ?? 'دانش‌آموز', avatar: j['avatar'] as String? ?? '👧',
    stars: j['stars'] as int? ?? 0,
    done: (j['done'] as List? ?? []).map((e) => e as int).toList());
}

class Lesson {
  const Lesson(this.title, this.signs, this.emoji, this.tip);
  final String title, signs, emoji, tip;
}

// ترتیب نشانه‌ها بر اساس جدول زمان‌بندی کتاب نگارش بارگذاری‌شده؛ متن درس‌ها بازنویسی نشده است.
const lessons = <Lesson>[
  Lesson('نگاره ۱ تا ۱۰', 'نگاره‌ها', '🖼️', 'آشنایی با تصویرها و گفت‌وگو'),
  Lesson('نشانه‌های آ و ب', 'آ  ا  ب', '🌷', 'نگاه کن، گوش بده و نشانه‌ها را پیدا کن'),
  Lesson('نشانه‌های اَ و د', 'اَ  د', '🦋', 'صدای نشانه‌ها را تمرین کن'),
  Lesson('نشانه‌های م و س', 'م  س', '🌼', 'نشانه‌ها را بخوان و بنویس'),
  Lesson('نشانه‌های او و ت', 'او  ت', '🎀', 'به شکل نشانه‌ها دقت کن'),
  Lesson('نشانه‌های ر و ن', 'ر  ن', '🌸', 'تمرین دیدن و نوشتن'),
  Lesson('نشانه‌های ای، ی و ز', 'ای  ی  ز', '🧚', 'نشانه‌ها را با صدای بلند بخوان'),
  Lesson('نشانه‌های اِ، ه و ش', 'اِ  ه  ش', '🌺', 'تمرین شنیدن و تشخیص'),
  Lesson('نشانه‌های ی و اُ', 'ی  اُ', '🦄', 'نشانه‌ها را پیدا کن'),
  Lesson('نشانه‌های ک و و', 'ک  و', '🌻', 'تمرین نوشتن با انگشت'),
  Lesson('نشانه‌های پ و گ', 'پ  گ', '🎈', 'نشانه‌ها را مرور کن'),
  Lesson('نشانه‌های ف و خ', 'ف  خ', '🌹', 'گوش بده و تکرار کن'),
  Lesson('نشانه‌های ق و ل', 'ق  ل', '🦋', 'تمرین دیداری و شنیداری'),
  Lesson('نشانه ج و استثنا', 'ج', '🌷', 'نشانه را درشت و آرام بنویس'),
  Lesson('نشانه‌های ه و چ', 'ه  چ', '🌼', 'تمرین نشانه‌ها'),
  Lesson('نشانه ژ و خوا', 'ژ  خوا', '🎀', 'به صدای واژه‌ها دقت کن'),
  Lesson('تشدید', 'ّ', '✨', 'با راهنمایی آموزگار تمرین کن'),
  Lesson('نشانه‌های ص و ذ', 'ص  ذ', '🌸', 'نشانه‌ها را تشخیص بده'),
  Lesson('نشانه‌های ع و ث', 'ع  ث', '🧚', 'تمرین خواندن و نوشتن'),
  Lesson('نشانه ح', 'ح', '🌺', 'نشانه را تمرین کن'),
  Lesson('نشانه‌های ض و ط', 'ض  ط', '🦄', 'مرور نشانه‌ها'),
  Lesson('نشانه غ و درس آزاد', 'غ', '🌻', 'تمرین با واژه‌های انتخابی آموزگار'),
  Lesson('نشانه ظ', 'ظ', '🎈', 'آفرین! نشانه‌ها را مرور کن'),
];

class MagicSchoolApp extends StatefulWidget {
  const MagicSchoolApp({super.key});
  @override
  State<MagicSchoolApp> createState() => _MagicSchoolAppState();
}
class _MagicSchoolAppState extends State<MagicSchoolApp> {
  List<Student> students = [];
  String? activeId;
  bool loading = true;
  Student? get active { for (final s in students) { if (s.id == activeId) return s; } return null; }

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('students_v1');
    if (raw != null) {
      try { students = (jsonDecode(raw) as List).map((e) => Student.fromJson(Map<String,dynamic>.from(e))).toList(); } catch (_) { students = []; }
    }
    activeId = p.getString('active_student');
    if (students.isNotEmpty && !students.any((s) => s.id == activeId)) activeId = students.first.id;
    if (mounted) setState(() => loading = false);
  }
  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('students_v1', jsonEncode(students.map((s) => s.toJson()).toList()));
    if (activeId != null) await p.setString('active_student', activeId!);
  }
  void _addStudent(String name, String avatar) {
    final s = Student(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name, avatar: avatar);
    setState(() { students.add(s); activeId = s.id; }); _save();
  }
  void _selectStudent(Student s) { setState(() => activeId = s.id); _save(); }
  void _award(int index) {
    final s = active; if (s == null || s.done.contains(index)) return;
    setState(() { s.done.add(index); s.stars += 1; }); _save();
  }
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'مدرسه جادویی من',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFFFF8FC), colorScheme: ColorScheme.fromSeed(seedColor: lilac), fontFamily: 'Roboto'),
    home: loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) : students.isEmpty
      ? StudentSetup(onAdd: _addStudent)
      : HomeScreen(students: students, active: active!, onSelect: _selectStudent, onAdd: _addStudent,
          onOpenLessons: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonsScreen(student: active!, onAward: _award)))),
  );
}

class StudentSetup extends StatefulWidget {
  const StudentSetup({super.key, required this.onAdd});
  final void Function(String, String) onAdd;
  @override State<StudentSetup> createState() => _StudentSetupState();
}
class _StudentSetupState extends State<StudentSetup> {
  final controller = TextEditingController(); String avatar = '👧';
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
    const Text('🌈', style: TextStyle(fontSize: 64)), const Text('مدرسه جادویی من', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ink)),
    const SizedBox(height: 8), const Text('اولین دانش‌آموز کوچولوی مدرسه را معرفی کن'), const SizedBox(height: 24),
    TextField(controller: controller, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'نام دانش‌آموز', border: OutlineInputBorder())),
    const SizedBox(height: 14), Wrap(spacing: 12, children: ['👧','🧒','🧚','🦄','🐱'].map((a) => ChoiceChip(label: Text(a, style: const TextStyle(fontSize: 24)), selected: avatar == a, onSelected: (_) => setState(() => avatar = a))).toList()),
    const SizedBox(height: 20), FilledButton(onPressed: () { final n = controller.text.trim(); if (n.isNotEmpty) widget.onAdd(n, avatar); }, child: const Text('شروع مدرسه')),
  ]))));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.students, required this.active, required this.onSelect, required this.onAdd, required this.onOpenLessons});
  final List<Student> students; final Student active; final void Function(Student) onSelect; final void Function(String,String) onAdd; final VoidCallback onOpenLessons;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('مدرسه جادویی من 🌈'), centerTitle: true, actions: [IconButton(tooltip: 'دانش‌آموزان', onPressed: () => showModalBottomSheet(context: context, builder: (_) => StudentPicker(students: students, active: active, onSelect: onSelect, onAdd: onAdd)), icon: const Icon(Icons.people_alt_rounded))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [pink,purple]), borderRadius: BorderRadius.circular(26)), child: Column(children: [Text(active.avatar, style: const TextStyle(fontSize: 48)), Text('سلام ${active.name} جان!', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: ink)), const Text('امروز قراره چیزهای تازه یاد بگیریم 🌸'), const SizedBox(height: 12), Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.star, color: Colors.orange), Text(' ${active.stars} ستاره  •  ${active.done.length} تمرین انجام‌شده')])]),
      const SizedBox(height: 20), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.18, children: [
        MenuTile(icon: '📚', title: 'کلاس فارسی', color: const Color(0xFFFFE5F0), onTap: onOpenLessons),
        MenuTile(icon: '✍️', title: 'تمرین نوشتن', color: const Color(0xFFE8E4FF), onTap: onOpenLessons),
        MenuTile(icon: '🎧', title: 'گوش کن و یاد بگیر', color: const Color(0xFFFFF0D8), onTap: onOpenLessons),
        MenuTile(icon: '⭐', title: 'ستاره‌های من', color: const Color(0xFFE2F6E9), onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('ستاره‌های من ⭐'), content: Text('${active.stars} ستاره جمع کردی!'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))]))),
      ]), const SizedBox(height: 16), const Center(child: Text('🌷  🦋  🌼  🎀  🌸', style: TextStyle(fontSize: 28))),
    ]));
}

class StudentPicker extends StatelessWidget {
  const StudentPicker({super.key, required this.students, required this.active, required this.onSelect, required this.onAdd});
  final List<Student> students; final Student active; final void Function(Student) onSelect; final void Function(String,String) onAdd;
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('انتخاب دانش‌آموز', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), ...students.map((s) => ListTile(leading: Text(s.avatar, style: const TextStyle(fontSize: 28)), title: Text(s.name), subtitle: Text('${s.stars} ستاره'), trailing: s.id == active.id ? const Icon(Icons.check_circle, color: Colors.green) : null, onTap: () { onSelect(s); Navigator.pop(context); })), const Divider(), TextButton.icon(onPressed: () { Navigator.pop(context); showDialog(context: context, builder: (_) => AddStudentDialog(onAdd: onAdd)); }, icon: const Icon(Icons.add), label: const Text('افزودن دانش‌آموز'))])));
}
class AddStudentDialog extends StatefulWidget { const AddStudentDialog({super.key, required this.onAdd}); final void Function(String,String) onAdd; @override State<AddStudentDialog> createState() => _AddStudentDialogState(); }
class _AddStudentDialogState extends State<AddStudentDialog> { final c = TextEditingController(); String a='👧'; @override void dispose(){c.dispose();super.dispose();} @override Widget build(BuildContext context)=>AlertDialog(title: const Text('دانش‌آموز جدید'), content: Column(mainAxisSize: MainAxisSize.min, children:[TextField(controller:c,decoration:const InputDecoration(labelText:'نام')), Wrap(children:['👧','🧒','🧚','🦄'].map((e)=>TextButton(onPressed:()=>setState(()=>a=e),child:Text(e,style:const TextStyle(fontSize:24)))).toList())]), actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('لغو')),FilledButton(onPressed:(){if(c.text.trim().isNotEmpty){widget.onAdd(c.text.trim(),a);Navigator.pop(context);}},child:const Text('ذخیره'))]); }

class MenuTile extends StatelessWidget { const MenuTile({super.key, required this.icon, required this.title, required this.color, required this.onTap}); final String icon,title; final Color color; final VoidCallback onTap; @override Widget build(BuildContext context)=>Material(color:color,borderRadius:BorderRadius.circular(22),child: InkWell(borderRadius:BorderRadius.circular(22),onTap:onTap,child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(icon,style:const TextStyle(fontSize:38)),const SizedBox(height:8),Text(title,style:const TextStyle(fontWeight:FontWeight.bold,color:ink))]))); }

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key, required this.student, required this.onAward}); final Student student; final void Function(int) onAward;
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('دفتر درس‌های من 📚')),body:ListView.builder(padding:const EdgeInsets.all(12),itemCount:lessons.length,itemBuilder:(context,i){final l=lessons[i];final done=student.done.contains(i);return Card(color:done?const Color(0xFFE8F7E9):Colors.white,child:ListTile(leading:CircleAvatar(backgroundColor:purple,child:Text(l.emoji,style:const TextStyle(fontSize:22))),title:Text(l.title,textDirection:TextDirection.rtl,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(done?'آفرین! این تمرین انجام شده':'برای شروع لمس کن',textDirection:TextDirection.rtl),trailing:done?const Icon(Icons.star,color:Colors.orange):const Icon(Icons.arrow_forward_ios,size:16),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(lesson:l,index:i,isDone:done,onAward:()=>onAward(i))))));}));
}

class LessonScreen extends StatefulWidget { const LessonScreen({super.key,required this.lesson,required this.index,required this.isDone,required this.onAward}); final Lesson lesson; final int index; final bool isDone; final VoidCallback onAward; @override State<LessonScreen> createState()=>_LessonScreenState(); }
class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  late final TabController tabs=TabController(length:3,vsync:this); final FlutterTts tts=FlutterTts(); final List<Offset?> points=[]; bool awarded=false;
  @override void dispose(){tabs.dispose();tts.stop();super.dispose();}
  Future<void> speak(String text) async { try { await tts.setLanguage('fa-IR'); await tts.setSpeechRate(0.38); await tts.speak(text); } catch (_) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('صدای فارسی روی این گوشی در دسترس نیست.'))); } }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.lesson.title)),body:Column(children:[Container(width:double.infinity,padding:const EdgeInsets.all(14),color:pink,child:Column(children:[Text(widget.lesson.emoji,style:const TextStyle(fontSize:36)),Text(widget.lesson.tip,textAlign:TextAlign.center,style:const TextStyle(color:ink))])),TabBar(controller:tabs,labelColor:lilac,tabs:const[Tab(text:'ببین و بخوان'),Tab(text:'گوش کن'),Tab(text:'بنویس')]),Expanded(child:TabBarView(controller:tabs,children:[
    Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(widget.lesson.signs,style:const TextStyle(fontSize:48,fontWeight:FontWeight.bold,color:ink),textDirection:TextDirection.rtl),const SizedBox(height:20),FilledButton.icon(onPressed:()=>speak(widget.lesson.signs),icon:const Icon(Icons.volume_up),label:const Text('شنیدن نشانه‌ها'))])),
    Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.headphones,size:70,color:lilac),const SizedBox(height:12),const Text('به نشانه‌ها گوش بده و تکرار کن'),const SizedBox(height:18),FilledButton.icon(onPressed:()=>speak(widget.lesson.signs),icon:const Icon(Icons.play_arrow),label:const Text('پخش صدا'))])),
    Padding(padding:const EdgeInsets.all(16),child:Column(children:[const Text('با انگشت روی صفحه بنویس',style:TextStyle(fontSize:18)),const SizedBox(height:12),Expanded(child:GestureDetector(onPanUpdate:(d)=>setState(()=>points.add(d.localPosition)),onPanEnd:(_)=>points.add(null),child:CustomPaint(painter:WritingPainter(points),size:Size.infinite,child:Container(decoration:BoxDecoration(color:Colors.white,border:Border.all(color:purple,width:2),borderRadius:BorderRadius.circular(18)))))),Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[TextButton.icon(onPressed:()=>setState(points.clear),icon:const Icon(Icons.delete_outline),label:const Text('پاک کردن')),FilledButton.icon(onPressed:()=>setState(()=>points.clear()),icon:const Icon(Icons.refresh),label:const Text('دوباره'))])])),
  ]))),Padding(padding:const EdgeInsets.all(14),child:FilledButton.icon(onPressed:widget.isDone||awarded?null:(){setState(()=>awarded=true);widget.onAward();ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('یک ستاره جادویی گرفتی! ⭐')));},icon:const Icon(Icons.star),label:Text(widget.isDone||awarded?'تمرین انجام شده':'پایان تمرین و دریافت ستاره')))]));
}
class WritingPainter extends CustomPainter { WritingPainter(this.points); final List<Offset?> points; @override void paint(Canvas canvas,Size size){final p=Paint()..color=lilac..strokeWidth=6..strokeCap=StrokeCap.round;for(var i=0;i<points.length-1;i++){final a=points[i],b=points[i+1];if(a!=null&&b!=null)canvas.drawLine(a,b,p);}} @override bool shouldRepaint(covariant WritingPainter old)=>old.points!=points; }
