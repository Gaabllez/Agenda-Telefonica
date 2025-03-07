import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda de Contatos',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
        ),
      ),
      themeMode: ThemeMode.system,
      home: ContactList(),
    );
  }
}

class Contact {
  int? id;
  String name;
  String phone;
  String email;

  Contact({this.id, required this.name, required this.phone, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
    };
  }

  Contact.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        phone = map['phone'],
        email = map['email'];
}

class ContactList extends StatefulWidget {
  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  late Database _database;
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  _initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'contacts.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE contacts(id INTEGER PRIMARY KEY, name TEXT, phone TEXT, email TEXT)',
        );
      },
    );
    _loadContacts();
  }

  _loadContacts() async {
    final List<Map<String, dynamic>> maps = await _database.query('contacts');
    setState(() {
      contacts = List.generate(maps.length, (i) {
        return Contact.fromMap(maps[i]);
      });
    });
  }

  _saveContact(Contact contact) async {
    if (contact.id == null) {
      await _database.insert('contacts', contact.toMap());
    } else {
      await _database.update(
        'contacts',
        contact.toMap(),
        where: 'id = ?',
        whereArgs: [contact.id],
      );
    }
    _loadContacts();
  }

  _deleteContact(Contact contact) async {
    await _database.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [contact.id],
    );
    _loadContacts();
  }

  _showContactForm(BuildContext context, Contact? contact) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final emailController = TextEditingController(text: contact?.email ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(contact == null ? 'Adicionar Contato' : 'Editar Contato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text;
                final phone = phoneController.text;
                final email = emailController.text;

                if (contact == null) {
                  final newContact = Contact(name: name, phone: phone, email: email);
                  _saveContact(newContact);
                } else {
                  contact.name = name;
                  contact.phone = phone;
                  contact.email = email;
                  _saveContact(contact);
                }

                Navigator.of(context).pop();
              },
              child: Text(contact == null ? 'Adicionar' : 'Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Agenda de Contatos')),
      body: contacts.isEmpty
          ? Center(child: Text('Nenhum contato encontrado'))
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            elevation: 3,
            child: ListTile(
              leading: Icon(Icons.account_circle, color: Colors.teal, size: 40),
              title: Text(contact.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(contact.phone),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.teal),
                    onPressed: () => _showContactForm(context, contact),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteContact(contact),
                  ),
                ],
              ),
              onTap: () => _showContactForm(context, contact),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactForm(context, null),
        child: Icon(Icons.add),
      ),
    );
  }
}
