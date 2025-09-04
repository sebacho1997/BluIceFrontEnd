import 'package:flutter/material.dart';

class PedidoScreen extends StatefulWidget {
  @override
  _PedidoScreenState createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  String selectedPaymentMethod = ''; // Método de pago seleccionado
  double totalAmount = 0.0; // Variable para almacenar el total a pagar
  int quantityWater = 0; // Cantidad de Botellón de Agua
  int quantityIce = 0; // Cantidad de Hielo

  @override
  void initState() {
    super.initState();
    _calculateTotal(); // Calcula el total al iniciar
  }

  void _calculateTotal() {
    // Suma de los precios de los productos
    setState(() {
      totalAmount = (quantityWater * 3.0) +
          (quantityIce * 2.5); // Actualiza los precios de los productos
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmar Pedido'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Has seleccionado:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.local_drink, color: Colors.blue),
                    title: Text('Botellón de Agua'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (quantityWater > 0) quantityWater--;
                              _calculateTotal();
                            });
                          },
                        ),
                        Text(quantityWater.toString()),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              quantityWater++;
                              _calculateTotal();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.ac_unit, color: Colors.blue),
                    title: Text('Hielo 1kg'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (quantityIce > 0) quantityIce--;
                              _calculateTotal();
                            });
                          },
                        ),
                        Text(quantityIce.toString()),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              quantityIce++;
                              _calculateTotal();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(thickness: 1),
            SizedBox(height: 10),
            Text(
              'Selecciona tu método de pago:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedPaymentMethod == 'QR' ? Colors.blue : Colors.white,
                foregroundColor:
                    selectedPaymentMethod == 'QR' ? Colors.white : Colors.black,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.blueAccent),
                ),
              ),
              onPressed: () {
                setState(() {
                  selectedPaymentMethod = 'QR';
                });
                _showQRDialog(context);
              },
              icon: Icon(Icons.qr_code),
              label: Text('Pagar por QR'),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPaymentMethod == 'Efectivo'
                    ? Colors.blueAccent
                    : Colors.white,
                foregroundColor: selectedPaymentMethod == 'Efectivo'
                    ? Colors.white
                    : Colors.black,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.blueAccent),
                ),
              ),
              onPressed: () {
                setState(() {
                  selectedPaymentMethod = 'Efectivo';
                });
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Pago en Efectivo'),
                    content: Text('Pagarás al momento de la entrega.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'))
                    ],
                  ),
                );
              },
              icon: Icon(Icons.attach_money),
              label: Text('Pagar en Efectivo'),
            ),
            Spacer(),
            Divider(thickness: 1),
            SizedBox(height: 10),
            // Total a pagar
            Text(
              'Total a pagar: \$${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (selectedPaymentMethod.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selecciona un método de pago')),
                  );
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Confirmar Pedido',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            bool paymentConfirmed = false;

            Future.delayed(Duration(seconds: 2), () {
              setState(() {
                paymentConfirmed = true;
              });
            });

            return AlertDialog(
              title: Text('Escanea el QR para realizar el pago'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/qr.jpg", // Aquí va tu imagen de QR real
                    width: 200,
                    height: 200,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        paymentConfirmed = !paymentConfirmed;
                      });
                      if (paymentConfirmed) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Pago confirmado exitosamente')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Verificando pago...')),
                        );
                      }
                    },
                    child: Text(
                      paymentConfirmed ? 'Pago confirmado' : 'Ya pagué',
                      style: TextStyle(
                        color: paymentConfirmed ? Colors.white : Colors.blue,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          paymentConfirmed ? Colors.green : Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
