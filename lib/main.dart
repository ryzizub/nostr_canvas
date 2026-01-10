import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:nostr_place/app/app.dart';
import 'package:nostr_place/app/app_bloc_observer.dart';

void main() {
  Bloc.observer = const AppBlocObserver();
  runApp(const App());
}
