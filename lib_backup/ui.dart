import 'package:flutter/material.dart' as m;
export 'package:flutter/material.dart' hide Text;

// ---------------------------------------------------------------
// Poori string jab bilkul match kare (zyada tar text yahan hai)
// Naya text translate karna ho to yahan ek line add kar dein
// ---------------------------------------------------------------
const Map<String, String> _exact = {
  // Login / Signup
  'Email aur password daalein': 'Please enter your email and password',
  'Student account banayein': 'Create student account',
  'Pehli baar? Account activate karein (sirf registered students)':
      'First time? Activate your account (registered students only)',
  'Roll No, Email aur kam az kam 6 harf ka password zaroori hai':
      'Roll No, email and a password of at least 6 characters are required',
  'Account ban gaya. Ab login karein': 'Account created. Please log in',
  'Sirf wo students account bana sakte hain jin ki fee jama hai aur jo university list mein hain.':
      'Only students who are on the university list and have paid their fee can create an account.',
  'Account banayein': 'Create account',

  // Teacher
  'Naya Course': 'New Course',
  'Code aur name zaroori hain': 'Course code and name are required',
  'Meri Courses': 'My Courses',
  'Abhi koi course nahi. Neeche + Course dabayein.':
      'No courses yet. Tap + Course below.',
  'Student add karein': 'Add Student',
  'Student add ho gaya': 'Student added',
  'Koi student enroll nahi': 'No students enrolled',
  'Attendance session shuru karein': 'Start an attendance session',
  'Abhi koi data nahi': 'No data yet',
  'Report copy ho gayi. Excel / Google Sheets mein paste karein':
      'Report copied. Paste it into Excel / Google Sheets',
  'Abhi koi session nahi': 'No sessions yet',
  'Is course mein koi student enroll nahi':
      'No students are enrolled in this course',

  // Session screen
  'Session shuru ho raha hai...': 'Starting session...',
  'Location le rahe hain...': 'Getting location...',
  'Location nahi mili. Location OFF karke session shuru karein ya permission dein.':
      'Location not available. Turn the location check off or grant permission.',
  'Session chal raha hai': 'Session is running',
  'Session khatam ho gaya': 'Session has ended',
  'Sirf class ke andar wale students': 'Only students inside the classroom',
  'QR har 10 second baad badalta hai': 'QR changes every 10 seconds',

  // Student
  'Naam': 'Name',
  'Check kar rahe hain...': 'Checking...',
  'Teacher ka QR scan karein': "Scan the teacher's QR code",
  'Aap kisi course mein enroll nahi hain': 'You are not enrolled in any course',
  'Abhi koi attendance record nahi': 'No attendance records yet',

  // Admin: users
  '(naam nahi)': '(no name)',
  'Role badlein': 'Change role',
  'Info edit karein': 'Edit info',
  'Info edit': 'Edit info',
  'Device: abhi koi registered nahi': 'Device: none registered yet',
  'Device reset karein': 'Reset device',
  'Account delete karein': 'Delete account',
  'Naya role chunein': 'Choose new role',
  'Role badal gaya': 'Role changed',
  'Save ho gaya': 'Saved',
  'Device reset ho gaya. Student agli scan par naya device register karega':
      'Device reset. The student will register a new device on the next scan',
  'Delete karein?': 'Delete?',
  'Delete ho gaya': 'Deleted',
  'Delete nahi hua. Agar teacher hai to pehle uske courses delete karein ya kisi aur ko dein.':
      'Could not delete. If this is a teacher, delete their courses first or reassign them.',
  'Student nahi mila ya error:': 'Student not found or error:',
  'Roll No ya Email': 'Roll No or Email',

  // Admin: courses / attendance
  'Pehle kam az kam ek teacher banayein (Users tab se role badlein)':
      'First create at least one teacher (change a role from the Users tab)',
  'Koi course nahi': 'No courses',
  'Course delete karein?': 'Delete course?',
  'Saare courses': 'All courses',
  'Koi attendance record nahi': 'No attendance records',

  // Admin: registry
  'Fee jama hai': 'Fee paid',
  'Roll No, naam, department aur semester zaroori hain':
      'Roll No, name, department and semester are required',
  'CSV paste karein': 'Paste CSV',
  'Har line: reg_no,naam,email,department,semester,fee_paid(true/false)':
      'Each line: reg_no,name,email,department,semester,fee_paid(true/false)',
  'Koi sahi line nahi mili': 'No valid lines found',

  // Theme
  'Default par wapas jayein': 'Reset to default',
};

// ---------------------------------------------------------------
// String ke andar ka hissa badalna (jahan $variable jurta hai)
// ---------------------------------------------------------------
const Map<String, String> _parts = {
  'Kuch masla aa gaya:': 'Something went wrong:',
  'Student nahi mila ya error:': 'Student not found or error:',
  'Error (shayad ye Student ID pehle se kisi aur ke paas hai):':
      'Error (this Student ID may already belong to someone else):',
  ' ka account aur uski saari attendance hamesha ke liye delete ho jayegi.':
      "'s account and all their attendance will be permanently deleted.",
  ' ki enrollments aur saari attendance bhi delete ho jayegi.':
      "'s enrollments and all attendance will also be deleted.",
  ' students import ho gaye': ' students imported',
  'Fee jama:': 'Fee paid:',
  'Baqi:': 'Remaining:',
  '(chal raha hai)': '(running)',

  // Database (server) ke messages
  'Ye Roll No university ki list mein nahi hai. Admin se rabta karein':
      'This Roll No is not in the university list. Please contact the admin',
  'Fee jama nahi hai. Fee jama hone ke baad account ban sakega':
      'Fee is not paid. You can create an account after the fee is paid',
  'Ye email is Roll No ke registered email se match nahi karti':
      'This email does not match the registered email for this Roll No',
  'Is Roll No ka account pehle se bana hua hai':
      'An account for this Roll No already exists',
  'Apna account delete nahi kar sakte': 'You cannot delete your own account',
};

final Map<String, String> _cache = {};
List<String>? _sortedKeys;

String tr(String s) {
  final c = _cache[s];
  if (c != null) return c;

  String out;
  if (_exact.containsKey(s)) {
    out = _exact[s]!;
  } else {
    _sortedKeys ??=
        (_parts.keys.toList()..sort((a, b) => b.length.compareTo(a.length)));
    out = s;
    for (final k in _sortedKeys!) {
      if (out.contains(k)) out = out.replaceAll(k, _parts[k]!);
    }
  }
  if (_cache.length < 3000) _cache[s] = out;
  return out;
}

// Ye class Flutter ke Text ki jagah le leti hai
class Text extends m.StatelessWidget {
  final String data;
  final m.TextStyle? style;
  final m.TextAlign? textAlign;
  final int? maxLines;
  final m.TextOverflow? overflow;
  final bool? softWrap;

  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  m.Widget build(m.BuildContext context) {
    return m.Text(
      tr(data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
