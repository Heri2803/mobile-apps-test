import 'package:flutter/material.dart';

class CounterProvider extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners(); // memberi tahu UI untuk rebuild
  }

  void decrement() {
    _count--;
    notifyListeners();
  }
}
