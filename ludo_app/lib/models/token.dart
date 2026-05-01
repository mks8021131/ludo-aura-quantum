class Token {
  final int id;
  int position; // -1: base, 0-51: common track, 52-56: home stretch, 57: home
  bool isFinished;
  bool isCaptured;
  
  Token({
    required this.id,
    this.position = -1,
    this.isFinished = false,
    this.isCaptured = false,
  });
}
