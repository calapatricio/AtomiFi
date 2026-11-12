import 'package:atomifi_cashew/atomifi_cashew.dart';

const header = 'account,amount,amount unpaid,currency,title,note,date,income,'
    'type,category name,subcategory name,color,icon,emoji,budget,objective,'
    'extra';

const export = '''
$header
Imagin,-0.5,,EUR,BiciMad,,2026-11-09 04:40:33.000,false,default,Transporte,,0XFFFFEB3B,tram,,,,repeat every 1 month
Imagin,21.2,,EUR,Bizum Moy,"Tacos - 14€
Cooltra - 4,5€",2026-11-08 03:15:08.000,true,default,Comida,,0XFF607D8B,cutlery,,,,
Imagin,-5.8,,EUR,Coviran,,2026-11-06 23:31:15.000,false,default,Ocio,Alcohol,0XFFFF7043,smiley,,,,
Cash,1500,,EUR,Payroll,,2026-10-28 09:00:00.000,true,default,Salario,,0XFF4CAF50,money,,,,
''';

CashewRow row({
  String account = 'Imagin',
  double amount = -5,
  String currencyCode = 'EUR',
  String title = 'Burger King',
  String note = '',
  DateTime? date,
  String category = 'Comida',
  String? subcategory,
}) =>
    CashewRow(
      account: account,
      amount: amount,
      currencyCode: currencyCode,
      title: title,
      note: note,
      date: date ?? DateTime(2026, 11, 2, 19, 40, 28),
      category: category,
      subcategory: subcategory,
    );

/// Ids that are easy to tell apart in a failing test: id-0, id-1, ...
String Function() sequentialIds() {
  var next = 0;
  return () => 'id-${next++}';
}
