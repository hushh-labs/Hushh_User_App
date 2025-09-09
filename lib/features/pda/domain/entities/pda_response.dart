import 'package:equatable/equatable.dart';

class PdaResponse extends Equatable {
  final String content;
  final double cost;

  const PdaResponse({required this.content, required this.cost});

  @override
  List<Object?> get props => [content, cost];
}
