import 'package:flutter/material.dart';
import 'package:xml_rpc/client.dart' as xml_rpc;
import 'dart:developer' as developer;

class Logger {
  static void log(String message) {
    final timestamp = DateTime.now().toString();
    final logMessage = '[$timestamp] $message';
    developer.log(logMessage);
    print(logMessage); // Also print to console
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  // Fill these values with your Odoo credentials
  // final String url = 'http://172.29.33.41:8069';  // Add http://
  final String url = 'https://edu-apiepployee.odoo.com';  // Add http://
  final String db = 'dev_01';    // Your database name
  final String username = 'admin';  // Your username
  final String password = 'admin';  // Your password

  Future<void> testConnection() async {
    try {
      final commonUrl = '$url/xmlrpc/2/common';
      Logger.log('Testing connection to: $commonUrl');

      // Test connection
      final version = await xml_rpc.call(
         Uri.parse(commonUrl),
         'version',
         [],
      );
      Logger.log('Version response: $version');

      // Try authentication
      final uid = await xml_rpc.call(
         Uri.parse(commonUrl),
         'authenticate',
         [db, username, password, {}],
      );
      Logger.log('Authentication response - UID: $uid');

      if (uid != null && uid is int) {
        // If authentication successful, try reading some data
        final objectUrl = '$url/xmlrpc/2/object';
        
        // Example: read partners
        final partners = await xml_rpc.call(
           Uri.parse(objectUrl),
           'execute_kw',
           [
            db,
            uid,
            password,
            'res.partner',  // model name
            'search_read',  // method
            [               // domain
              [['is_company', '=', true]]  // only companies
            ],
            {             // options
              'fields': ['name', 'email', 'phone'],
              'limit': 5,
            }
          ],
        );
        Logger.log('Partners found: $partners');

        // Example: read products
        final products = await xml_rpc.call(
           Uri.parse(objectUrl),
           'execute_kw',
           [
            db,
            uid,
            password,
            'product.template',  // model name
            'search_read',      // method
            [[]],              // empty domain = all records
            {                  // options
              'fields': ['name', 'list_price', 'default_code'],
              'limit': 5,
            }
          ],
        );
        Logger.log('Products found: $products');

        // Example: read sales orders
        final sales = await xml_rpc.call(
           Uri.parse(objectUrl),
           'execute_kw',
           [
            db,
            uid,
            password,
            'sale.order',    // model name
            'search_read',   // method
            [               // domain
              [['state', 'not in', ['draft', 'cancel']]]  // confirmed orders
            ],
            {             // options
              'fields': ['name', 'partner_id', 'amount_total', 'date_order'],
              'limit': 5,
            }
          ],
        );
        Logger.log('Sales orders found: $sales');
      }
    } catch (e) {
      Logger.log('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Odoo XML-RPC Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: testConnection,
          child: Text('Test Connection'),
        ),
      ),
    );
  }
}