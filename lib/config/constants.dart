// Backend Connection
// ignore_for_file: constant_identifier_names

const String BASE_URL = 'https://brave-pillows-tie.loca.lt';
const String WS_URL = 'wss://brave-pillows-tie.loca.lt';
const bool kMockMode =
    false; // 👈 Make sure this is FALSE so it actually hits the backend!
// Dummy data for the entire app — zero empty screens

class DummyData {
  static const emergencies = [
    {'id': 'police', 'title': 'Police Stopped Me', 'icon': 'local_police', 'color': '0xFF2563EB'},
    {'id': 'arrest', 'title': 'Arrest Situation', 'icon': 'gavel', 'color': '0xFFDC2626'},
    {'id': 'domestic', 'title': 'Domestic Violence', 'icon': 'family_restroom', 'color': '0xFF9333EA'},
    {'id': 'cyber', 'title': 'Cyber Crime', 'icon': 'language', 'color': '0xFF0284C7'},
    {'id': 'workplace', 'title': 'Workplace Issue', 'icon': 'work', 'color': '0xFFD97706'},
    {'id': 'property', 'title': 'Property Dispute', 'icon': 'home_work', 'color': '0xFF059669'},
  ];

  static const helplines = [
    {'title': 'Police', 'number': '100', 'icon': 'local_police'},
    {'title': 'Women', 'number': '181', 'icon': 'female'},
    {'title': 'Ambulance', 'number': '108', 'icon': 'local_hospital'},
    {'title': 'Child', 'number': '1098', 'icon': 'child_care'},
  ];

  static const Map<String, Map<String, dynamic>> rightsData = {
    'police': {
      'title': 'Police Stopped You',
      'rights': [
        'You have the right to know the reason for being stopped (CrPC Section 50)',
        'You cannot be detained without being told the grounds of arrest (Article 22)',
        'You have the right to remain silent (Article 20(3))',
        'You can refuse a search without a warrant (CrPC Section 93)',
        'Female suspects can only be searched by a female officer (CrPC Section 51)',
        'You have the right to make a phone call to a family member',
        'Police must identify themselves with name and badge number',
      ],
      'whatToSay': [
        '"I am exercising my right to remain silent."',
        '"Am I being detained or am I free to go?"',
        '"I would like to speak to a lawyer before answering questions."',
        '"Please show me the warrant."',
        '"I do not consent to a search."',
      ],
    },
    'arrest': {
      'title': 'Arrest Situation',
      'rights': [
        'You must be informed of the grounds of arrest (Article 22(1))',
        'You have the right to consult a lawyer (Article 22(1))',
        'You must be produced before a magistrate within 24 hours (Article 22(2))',
        'You cannot be subjected to torture or inhuman treatment (Article 21)',
        'A memo of arrest must be prepared (DK Basu Guidelines)',
        'A family member must be informed of your arrest',
        'You have the right to free legal aid (Article 39A)',
      ],
      'whatToSay': [
        '"I want to see the arrest memo."',
        '"Please inform my family immediately."',
        '"I want to consult with my lawyer."',
      ],
    },
  };

  static const rightsCategories = ['Fundamental', 'Arrest & Detention', 'Property', 'Cyber', 'Workplace'];

  static const fundamentalRights = [
    {'title': 'Right to Equality', 'articles': 'Art 14-18', 'desc': 'All citizens are equal before the law. The State shall not discriminate on grounds of religion, race, caste, sex or place of birth. Untouchability is abolished and its practice is forbidden.'},
    {'title': 'Right to Freedom', 'articles': 'Art 19-22', 'desc': 'Protection of 6 freedoms: speech and expression, assembly, association, movement, residence, and profession. Protection against arrest and detention in certain cases.'},
    {'title': 'Right against Exploitation', 'articles': 'Art 23-24', 'desc': 'Prohibition of trafficking and forced labour. Prohibition of employment of children below 14 years in factories, mines and hazardous employment.'},
    {'title': 'Right to Freedom of Religion', 'articles': 'Art 25-28', 'desc': 'Freedom of conscience and free profession, practice and propagation of religion. Freedom to manage religious affairs.'},
    {'title': 'Right to Constitutional Remedies', 'articles': 'Art 32', 'desc': 'The right to move the Supreme Court for the enforcement of fundamental rights. Dr. Ambedkar called this the "heart and soul" of the Constitution.'},
  ];

  static const lawyers = [
    {'name':'Adv. Priya Sharma','spec':'Criminal Law','city':'Delhi','rating':4.9,'won':312,'total':350,'badge':'Gold','experience':'15 years','about':'Senior Criminal advocate practicing at the Delhi High Court. Specialized in high-stakes criminal defense.','price':2500},
    {'name':'Adv. Rajesh Kumar','spec':'Property Law','city':'Mumbai','rating':4.8,'won':456,'total':480,'badge':'Platinum','experience':'22 years','about':'Property dispute specialist with extensive experience in land litigation.','price':3500},
    {'name':'Adv. Meera Patel','spec':'Family Law','city':'Bangalore','rating':4.7,'won':178,'total':195,'badge':'Gold','experience':'12 years','about':'Family & divorce expert helping clients navigate complex domestic issues.','price':2000},
    {'name':'Adv. Vikram Singh','spec':'Corporate Law','city':'Hyderabad','rating':4.6,'won':104,'total':120,'badge':'Silver','experience':'8 years','about':'Startup & corporate specialist focused on NCLT and company law.','price':4000},
    {'name':'Adv. Anita Desai','spec':'Cyber Law','city':'Pune','rating':4.9,'won':82,'total':89,'badge':'Gold','experience':'7 years','about':'Cyber crime & IT law expert helping victims of digital fraud.','price':1800},
    {'name':'Adv. Sanjay Gupta','spec':'Criminal Law','city':'Chennai','rating':4.5,'won':231,'total':267,'badge':'Silver','experience':'20 years','about':'High court criminal lawyer with a focus on civil liberties.','price':2200},
  ];

  static const aiTemplates = ['Property dispute with neighbor', 'Terminated without notice', 'Defective product refund', 'Cyber harassment'];

  static const aiDummyResult = 'Based on your description, this falls under Section 420 of the Indian Penal Code (Cheating and dishonestly inducing delivery of property). The Consumer Protection Act 2019 also provides remedies for defective goods and deficiency in services.\n\nYou should immediately file a written complaint with the consumer forum within 2 years from the date of cause of action.';
  
  static const aiRelevantLaws = [
    'IPC Section 420 — Cheating and dishonestly inducing delivery of property',
    'Consumer Protection Act 2019 — Section 35',
    'Information Technology Act 2000 — Section 66D',
  ];

  static const evidenceViolations = [
    'Document lacks a valid notary stamp (Indian Registration Act)',
    'Violates 30-day notice mandate — Rent Control Act Section 106',
    'Illegal eviction notice — IPC Section 441 (Criminal Trespass)',
  ];

  static const evidenceNextSteps = [
    'File complaint at local magistrate court',
    'Contact District Legal Services Authority (DLSA)',
    'Preserve original document as evidence',
    'Apply for stay order at civil court',
  ];

  static const cases = [
    {'id': 'MN-23109', 'title': 'Property Dispute Resolution', 'client': 'Arjun Sharma', 'lawyer': 'Adv. Rajesh Kumar', 'risk': 'MEDIUM', 'progress': 0.4, 'filed': '10/15/2025', 'winRate': 0.72},
    {'id': 'MN-23110', 'title': 'Criminal Defense — IPC 376', 'client': 'Rahul Mehta', 'lawyer': 'Adv. Priya Sharma', 'risk': 'HIGH', 'progress': 0.2, 'filed': '11/03/2025', 'winRate': 0.45},
    {'id': 'MN-23111', 'title': 'Consumer Complaint — NCDRC', 'client': 'Deepa Singh', 'lawyer': 'Adv. Meera Patel', 'risk': 'LOW', 'progress': 0.8, 'filed': '08/22/2025', 'winRate': 0.91},
    {'id': 'MN-23112', 'title': 'Cyber Fraud Investigation', 'client': 'Kiran Rao', 'lawyer': 'Adv. Anita Desai', 'risk': 'MEDIUM', 'progress': 0.55, 'filed': '09/18/2025', 'winRate': 0.68},
  ];

  static const evidenceChecklist = [
    {'item': 'Bank Statement (verified)', 'done': true},
    {'item': 'Property Tax Receipt', 'done': true},
    {'item': 'Rent Agreement Page 2', 'done': false},
    {'item': 'Witness Statement — Neighbor', 'done': false},
    {'item': 'Municipal Corporation Notice', 'done': false},
  ];
}
