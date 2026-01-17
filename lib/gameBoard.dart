import 'package:chess/components/pieces.dart';
import 'package:chess/components/square.dart';
import 'package:chess/values/colors.dart';
import 'package:flutter/material.dart';

import 'components/dead_piece.dart';
import 'helper/helper_function.dart';

class BoardGame extends StatefulWidget {
  const BoardGame({Key? key}) : super(key: key);

  @override
  State<BoardGame> createState() => _BoardGameState();
}

class _BoardGameState extends State<BoardGame> {
  late List<List<ChessPiece?>> board;
  // The currently selected piece on the chess board,
// If no piece is selected, this is null.
  ChessPiece? selectedPiece;
// The row index of the selected piece
// Default value -1 indicated no piece is currently selected;
  int selectedRow = -1;

// The Column index of the selected piece
// Default value -1 indicated no piece is currently selected;
  int selectedCol = -1;
  List<List<int>> validMoves = [];

  List<ChessPiece> whitePiecesTaken = [];

  List<ChessPiece> blackPiecesTaken = [];

  bool isWhiteTurn = true;

  List<int> whiteKingPosition = [7, 4];
  List<int> blackKingPosition = [0, 4];
  bool checkStatus = false;

  // En Passant uchun - oxirgi yurish ikki qadam bo'lgan piyodaning pozitsiyasi
  List<int>? enPassantTarget;

  // Rokada uchun - shoh va tura harakatlangan yoki yo'qligini kuzatish
  bool whiteKingMoved = false;
  bool blackKingMoved = false;
  bool whiteLeftRookMoved = false;
  bool whiteRightRookMoved = false;
  bool blackLeftRookMoved = false;
  bool blackRightRookMoved = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    // initialize the board with nulls, meaning no pieces in those positions.
    List<List<ChessPiece?>> newBoard =
        List.generate(8, (index) => List.generate(8, (index) => null));

    // Place pawns
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPiecesType.pawn,
        isWhite: false,
        imagePath: 'images/pawn.png',
      );

      newBoard[6][i] = ChessPiece(
        type: ChessPiecesType.pawn,
        isWhite: true,
        imagePath: 'images/pawn.png',
      );
    }

    // Place rooks
    newBoard[0][0] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: false,
        imagePath: "images/rook.png");
    newBoard[0][7] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: false,
        imagePath: "images/rook.png");
    newBoard[7][0] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: true,
        imagePath: "images/rook.png");
    newBoard[7][7] = ChessPiece(
        type: ChessPiecesType.rook,
        isWhite: true,
        imagePath: "images/rook.png");

    // Place knights
    newBoard[0][1] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: false,
        imagePath: "images/knight.png");
    newBoard[0][6] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: false,
        imagePath: "images/knight.png");
    newBoard[7][1] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: true,
        imagePath: "images/knight.png");
    newBoard[7][6] = ChessPiece(
        type: ChessPiecesType.knight,
        isWhite: true,
        imagePath: "images/knight.png");

    // Place bishops
    newBoard[0][2] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: false,
        imagePath: "images/bishop.png");

    newBoard[0][5] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: false,
        imagePath: "images/bishop.png");
    newBoard[7][2] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: true,
        imagePath: "images/bishop.png");
    newBoard[7][5] = ChessPiece(
        type: ChessPiecesType.bishop,
        isWhite: true,
        imagePath: "images/bishop.png");

    // Place queens
    newBoard[0][3] = ChessPiece(
      type: ChessPiecesType.queen,
      isWhite: false,
      imagePath: 'images/queen.png',
    );
    newBoard[7][3] = ChessPiece(
      type: ChessPiecesType.queen,
      isWhite: true,
      imagePath: 'images/queen.png',
    );

    // Place kings
    newBoard[0][4] = ChessPiece(
      type: ChessPiecesType.king,
      isWhite: false,
      imagePath: 'images/king.png',
    );
    newBoard[7][4] = ChessPiece(
      type: ChessPiecesType.king,
      isWhite: true,
      imagePath: 'images/king.png',
    );

    board = newBoard;
  }

// USER SELECTED A PIECE
  void pieceSelected(int row, int col) {
    setState(() {
      if (selectedPiece == null && board[row][col] != null) {
        if (board[row][col]!.isWhite == isWhiteTurn) {
          selectedPiece = board[row][col];
          selectedRow = row;
          selectedCol = col;
        }
      } else if (board[row][col] != null &&
          board[row][col]!.isWhite == selectedPiece!.isWhite) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
      } else if (selectedPiece != null &&
          validMoves.any((element) => element[0] == row && element[1] == col)) {
        movePiece(row, col);
      }

      validMoves = calculateRealValidMoves(
          selectedRow, selectedCol, selectedPiece, true);
    });
  }

  List<List<int>> calculateRowValidMoves(int row, int col, ChessPiece? piece, {bool checkCastling = true}) {
    List<List<int>> candidateMoves = [];

    if (piece == null) {
      return [];
    }

    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPiecesType.pawn:
        // Check the square immediately in front of the pawn
        if (isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          candidateMoves.add([row + direction, col]);
        }

        // If it's the pawn's first move (row is either 1 for black pawns or 6 for white ones), check the square two steps ahead
        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (isInBoard(row + 2 * direction, col) &&
              board[row + 2 * direction][col] == null &&
              board[row + direction][col] == null) {
            candidateMoves.add([row + 2 * direction, col]);
          }
        }

        // Check for possible captures
        if (isInBoard(row + direction, col - 1) &&
            board[row + direction][col - 1] != null &&
            board[row + direction][col - 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col - 1]);
        }
        if (isInBoard(row + direction, col + 1) &&
            board[row + direction][col + 1] != null &&
            board[row + direction][col + 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col + 1]);
        }

        // En Passant
        if (enPassantTarget != null) {
          // Chapga en passant
          if (row == enPassantTarget![0] &&
              col - 1 == enPassantTarget![1] &&
              board[row][col - 1] != null &&
              board[row][col - 1]!.isWhite != piece.isWhite) {
            candidateMoves.add([row + direction, col - 1]);
          }
          // O'ngga en passant
          if (row == enPassantTarget![0] &&
              col + 1 == enPassantTarget![1] &&
              board[row][col + 1] != null &&
              board[row][col + 1]!.isWhite != piece.isWhite) {
            candidateMoves.add([row + direction, col + 1]);
          }
        }
        break;

      case ChessPiecesType.rook:
        // horizontal and vertical directions
        var directions = [
          [-1, 0], // up
          [1, 0], // down
          [0, -1], //left
          [0, 1], //right
        ];
        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves
                    .add([newRow, newCol]); // can capture opponent's piece
              }
              break; // blocked by own piece or after capturing
            }
            candidateMoves.add([newRow, newCol]); // an empty valid square
            i++;
          }
        }
        break;

      case ChessPiecesType.knight:
        // all eight possible L shapes the knight can move
        var knightMoves = [
          [-2, -1], // up 2 left 1
          [-2, 1], // up 2 right 1
          [-1, -2], // up 1 left 2
          [-1, 2], // up 1 right 2
          [1, -2], // down 1 left 2
          [1, 2], // down 1 right 2
          [2, -1], // down 2 left 1
          [2, 1], // down 2 right 1
        ];
        for (var move in knightMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) {
            continue;
          }
          // if the new position is empty or there is an opponent's piece there
          if (board[newRow][newCol] == null ||
              board[newRow][newCol]!.isWhite != piece.isWhite) {
            candidateMoves.add([newRow, newCol]);
          }
        }
        break;

      case ChessPiecesType.bishop:
        // diagonal directions
        var directions = [
          [-1, -1], // up-left
          [-1, 1], // up-right
          [1, -1], // down-left
          [1, 1], // down-right
        ];
        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // capture
              }
              break; // blocked
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPiecesType.queen:
        // Queen can move in any direction, combining the moves of a rook and a bishop
        var directions = [
          [-1, 0], // up
          [1, 0], // down
          [0, -1], // left
          [0, 1], // right
          [-1, -1], // up-left
          [-1, 1], // up-right
          [1, -1], // down-left
          [1, 1] // down-right
        ];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];

            if (!isInBoard(newRow, newCol)) {
              break;
            }

            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // capture
              }
              break; // blocked
            }
            candidateMoves.add([newRow, newCol]); // free space
            i++;
          }
        }
        break;

      case ChessPiecesType.king:
        var kingMoves = [
          [-1, -1], // Up-left
          [-1, 0], // Up
          [-1, 1], // Up-right
          [0, -1], // Left
          [0, 1], // Right
          [1, -1], // Down-left
          [1, 0], // Down
          [1, 1] // Down-right
        ];

        for (var move in kingMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];

          if (!isInBoard(newRow, newCol)) {
            continue;
          }

          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]); // Can capture
            }
            continue; // Square is blocked by a piece of the same color
          }
          candidateMoves.add([newRow, newCol]);
        }

        // Rokada (Castling) - faqat checkCastling true bo'lganda tekshiriladi
        if (checkCastling) {
          if (piece.isWhite && !whiteKingMoved && !isKingInCheckSimple(true)) {
            // Oq shoh qisqa rokada (O-O) - o'ng tomonga
            if (!whiteRightRookMoved &&
                board[7][5] == null &&
                board[7][6] == null &&
                board[7][7]?.type == ChessPiecesType.rook &&
                board[7][7]?.isWhite == true) {
              // Shoh o'tadigan kataklar xavfsiz ekanligini tekshirish
              if (!isSquareUnderAttackSimple(7, 5, true) &&
                  !isSquareUnderAttackSimple(7, 6, true)) {
                candidateMoves.add([7, 6]); // Qisqa rokada
              }
            }
            // Oq shoh uzun rokada (O-O-O) - chap tomonga
            if (!whiteLeftRookMoved &&
                board[7][1] == null &&
                board[7][2] == null &&
                board[7][3] == null &&
                board[7][0]?.type == ChessPiecesType.rook &&
                board[7][0]?.isWhite == true) {
              if (!isSquareUnderAttackSimple(7, 2, true) &&
                  !isSquareUnderAttackSimple(7, 3, true)) {
                candidateMoves.add([7, 2]); // Uzun rokada
              }
            }
          } else if (!piece.isWhite && !blackKingMoved && !isKingInCheckSimple(false)) {
            // Qora shoh qisqa rokada
            if (!blackRightRookMoved &&
                board[0][5] == null &&
                board[0][6] == null &&
                board[0][7]?.type == ChessPiecesType.rook &&
                board[0][7]?.isWhite == false) {
              if (!isSquareUnderAttackSimple(0, 5, false) &&
                  !isSquareUnderAttackSimple(0, 6, false)) {
                candidateMoves.add([0, 6]);
              }
            }
            // Qora shoh uzun rokada
            if (!blackLeftRookMoved &&
                board[0][1] == null &&
                board[0][2] == null &&
                board[0][3] == null &&
                board[0][0]?.type == ChessPiecesType.rook &&
                board[0][0]?.isWhite == false) {
              if (!isSquareUnderAttackSimple(0, 2, false) &&
                  !isSquareUnderAttackSimple(0, 3, false)) {
                candidateMoves.add([0, 2]);
              }
            }
          }
        }
        break;

      default:
    }
    return candidateMoves;
  }

  List<List<int>> calculateRealValidMoves(
      int row, int col, ChessPiece? piece, bool checkSimulation) {
    List<List<int>> realValidMoves = [];
    List<List<int>> candidateMoves = calculateRowValidMoves(row, col, piece);
    if (checkSimulation) {
      for (var move in candidateMoves) {
        int endRow = move[0];
        int endCol = move[1];
        if (simulatedMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realValidMoves.add(move);
        }
      }
    } else {
      realValidMoves = candidateMoves;
    }
    return realValidMoves;
  }

  void movePiece(int newRow, int newCol) {
    // En Passant capture - piyoda diagonal bo'sh katak ga yursa
    if (selectedPiece?.type == ChessPiecesType.pawn &&
        board[newRow][newCol] == null &&
        selectedCol != newCol) {
      // Bu en passant harakati
      var capturedPiece = board[selectedRow][newCol];
      if (capturedPiece != null) {
        if (capturedPiece.isWhite) {
          whitePiecesTaken.add(capturedPiece);
        } else {
          blackPiecesTaken.add(capturedPiece);
        }
        board[selectedRow][newCol] = null; // Yonidagi piyodani olib tashlash
      }
    }

    // Oddiy capture - agar yangi joyda raqib donasi bo'lsa
    if (board[newRow][newCol] != null) {
      var capturedPiece = board[newRow][newCol];
      if (capturedPiece!.isWhite) {
        whitePiecesTaken.add(capturedPiece);
      } else {
        blackPiecesTaken.add(capturedPiece);
      }
    }

    // En Passant target ni yangilash - piyoda 2 qadam yurganda
    if (selectedPiece?.type == ChessPiecesType.pawn &&
        (selectedRow - newRow).abs() == 2) {
      enPassantTarget = [newRow, newCol];
    } else {
      enPassantTarget = null;
    }

    // Rokada harakati - shoh 2 katak yurganda turni ham ko'chirish
    if (selectedPiece?.type == ChessPiecesType.king) {
      int colDiff = newCol - selectedCol;

      if (colDiff == 2) {
        // Qisqa rokada (O-O) - tura o'ng tomondan
        if (selectedPiece!.isWhite) {
          board[7][5] = board[7][7]; // Tura yangi joyga
          board[7][7] = null;
        } else {
          board[0][5] = board[0][7];
          board[0][7] = null;
        }
      } else if (colDiff == -2) {
        // Uzun rokada (O-O-O) - tura chap tomondan
        if (selectedPiece!.isWhite) {
          board[7][3] = board[7][0];
          board[7][0] = null;
        } else {
          board[0][3] = board[0][0];
          board[0][0] = null;
        }
      }

      // Shoh pozitsiyasini yangilash
      if (selectedPiece!.isWhite) {
        whiteKingPosition = [newRow, newCol];
        whiteKingMoved = true;
      } else {
        blackKingPosition = [newRow, newCol];
        blackKingMoved = true;
      }
    }

    // Tura harakatini kuzatish (rokada uchun)
    if (selectedPiece?.type == ChessPiecesType.rook) {
      if (selectedPiece!.isWhite) {
        if (selectedRow == 7 && selectedCol == 0) whiteLeftRookMoved = true;
        if (selectedRow == 7 && selectedCol == 7) whiteRightRookMoved = true;
      } else {
        if (selectedRow == 0 && selectedCol == 0) blackLeftRookMoved = true;
        if (selectedRow == 0 && selectedCol == 7) blackRightRookMoved = true;
      }
    }

    // Donani yangi joyga ko'chirish
    board[newRow][newCol] = selectedPiece;
    board[selectedRow][selectedCol] = null;

    // Piyoda promotion - oxirgi qatorga yetganda
    if (selectedPiece?.type == ChessPiecesType.pawn) {
      if ((selectedPiece!.isWhite && newRow == 0) ||
          (!selectedPiece!.isWhite && newRow == 7)) {
        _showPromotionDialog(newRow, newCol, selectedPiece!.isWhite);
      }
    }

    if (isKingInCheck(!isWhiteTurn)) {
      checkStatus = true;
    } else {
      checkStatus = false;
    }

    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
    });

    // Checkmate yoki Stalemate tekshirish
    if (isCheckMate(!isWhiteTurn)) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text("SHOH MAT!"),
                content: Text(isWhiteTurn ? "Qora g'alaba qozondi!" : "Oq g'alaba qozondi!"),
                actions: [
                  TextButton(
                      onPressed: resetGame, child: const Text("Qayta boshlash"))
                ],
              ));
    } else if (isStalemate(!isWhiteTurn)) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text("PAT!"),
                content: const Text("O'yin durrang bilan tugadi."),
                actions: [
                  TextButton(
                      onPressed: resetGame, child: const Text("Qayta boshlash"))
                ],
              ));
    }

    isWhiteTurn = !isWhiteTurn;
  }

  // Piyoda promotion dialog
  void _showPromotionDialog(int row, int col, bool isWhite) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Piyodani almashtiring"),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _promotionOption(row, col, ChessPiecesType.queen, isWhite),
            _promotionOption(row, col, ChessPiecesType.rook, isWhite),
            _promotionOption(row, col, ChessPiecesType.bishop, isWhite),
            _promotionOption(row, col, ChessPiecesType.knight, isWhite),
          ],
        ),
      ),
    );
  }

  Widget _promotionOption(int row, int col, ChessPiecesType type, bool isWhite) {
    String imagePath;
    switch (type) {
      case ChessPiecesType.queen:
        imagePath = 'images/queen.png';
        break;
      case ChessPiecesType.rook:
        imagePath = 'images/rook.png';
        break;
      case ChessPiecesType.bishop:
        imagePath = 'images/bishop.png';
        break;
      case ChessPiecesType.knight:
        imagePath = 'images/knight.png';
        break;
      default:
        imagePath = 'images/queen.png';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          board[row][col] = ChessPiece(
            type: type,
            isWhite: isWhite,
            imagePath: imagePath,
          );
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
        ),
        child: Image.asset(
          imagePath,
          height: 40,
          width: 40,
          color: isWhite ? null : Colors.black,
        ),
      ),
    );
  }

  bool isKingInCheck(bool isWhiteKing) {
    List<int> kingPosition =
        isWhiteKing ? whiteKingPosition : blackKingPosition;

    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
          continue;
        }
        List<List<int>> pieceValidMoves =
            calculateRealValidMoves(i, j, board[i][j], false);

        for (List<int> move in pieceValidMoves) {
          if (move[0] == kingPosition[0] && move[1] == kingPosition[1]) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Berilgan katak raqib donalar tomonidan hujum ostida yoki yo'qligini tekshirish
  bool isSquareUnderAttack(int row, int col, bool isWhite) {
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite == isWhite) {
          continue;
        }
        List<List<int>> pieceValidMoves =
            calculateRowValidMoves(i, j, board[i][j]);

        for (List<int> move in pieceValidMoves) {
          if (move[0] == row && move[1] == col) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Rekursiyasiz sodda versiya - rokada tekshirish uchun
  bool isSquareUnderAttackSimple(int row, int col, bool isWhite) {
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite == isWhite) {
          continue;
        }
        // checkCastling: false - rekursiyani oldini olish uchun
        List<List<int>> pieceValidMoves =
            calculateRowValidMoves(i, j, board[i][j], checkCastling: false);

        for (List<int> move in pieceValidMoves) {
          if (move[0] == row && move[1] == col) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Rekursiyasiz sodda versiya - rokada tekshirish uchun
  bool isKingInCheckSimple(bool isWhiteKing) {
    List<int> kingPosition =
        isWhiteKing ? whiteKingPosition : blackKingPosition;

    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite == isWhiteKing) {
          continue;
        }
        // checkCastling: false - rekursiyani oldini olish uchun
        List<List<int>> pieceValidMoves =
            calculateRowValidMoves(i, j, board[i][j], checkCastling: false);

        for (List<int> move in pieceValidMoves) {
          if (move[0] == kingPosition[0] && move[1] == kingPosition[1]) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool simulatedMoveIsSafe(
      ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    ChessPiece? originalDestinationPiece = board[endRow][endCol];

    List<int>? originalKingPosition;
    if (piece.type == ChessPiecesType.king) {
      originalKingPosition =
          piece.isWhite ? whiteKingPosition : blackKingPosition;

      if (piece.isWhite) {
        whiteKingPosition = [endRow, endCol];
      } else {
        blackKingPosition = [endRow, endCol];
      }
    }

    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    bool kingInCheck = isKingInCheck(piece.isWhite);

    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    if (piece.type == ChessPiecesType.king) {
      if (piece.isWhite) {
        whiteKingPosition = originalKingPosition!;
      } else {
        blackKingPosition = originalKingPosition!;
      }
    }
    return !kingInCheck;
  }

  bool isCheckMate(bool isWhiteKing) {
    if (!isKingInCheck(isWhiteKing)) {
      return false;
    }
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite != isWhiteKing) {
          continue;
        }
        List<List<int>> validMoves =
            calculateRealValidMoves(i, j, board[i][j]!, true);
        if (validMoves.isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  // Pat holati - shoh hujum ostida emas, lekin hech qanday legal yurish yo'q
  bool isStalemate(bool isWhiteKing) {
    // Agar shoh hujum ostida bo'lsa, bu pat emas
    if (isKingInCheck(isWhiteKing)) {
      return false;
    }

    // Har bir dona uchun legal yurish bor yoki yo'qligini tekshirish
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (board[i][j] == null || board[i][j]!.isWhite != isWhiteKing) {
          continue;
        }
        List<List<int>> validMoves =
            calculateRealValidMoves(i, j, board[i][j]!, true);
        if (validMoves.isNotEmpty) {
          return false; // Kamida bitta legal yurish bor
        }
      }
    }
    return true; // Hech qanday legal yurish yo'q = PAT
  }

  void resetGame() {
    Navigator.pop(context);
    _resetGameState();
  }

  // Dialog ochilmagan holda o'yinni qayta boshlash
  void _resetGameState() {
    _initializeBoard();
    checkStatus = false;
    whitePiecesTaken.clear();
    blackPiecesTaken.clear();
    whiteKingPosition = [7, 4];
    blackKingPosition = [0, 4];
    isWhiteTurn = true;
    // Yangi state o'zgaruvchilarni tozalash
    enPassantTarget = null;
    whiteKingMoved = false;
    blackKingMoved = false;
    whiteLeftRookMoved = false;
    whiteRightRookMoved = false;
    blackLeftRookMoved = false;
    blackRightRookMoved = false;
    selectedPiece = null;
    selectedRow = -1;
    selectedCol = -1;
    validMoves = [];
    setState(() {});
  }

  // O'yinni qayta boshlash (tugma orqali)
  void restartGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Qayta boshlash"),
        content: const Text("O'yinni qayta boshlamoqchimisiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Yo'q"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGameState();
            },
            child: const Text("Ha"),
          ),
        ],
      ),
    );
  }

  // Resign qilish
  void resign(bool isWhiteResigning) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWhiteResigning ? "Oq taslim bo'ldi!" : "Qora taslim bo'ldi!"),
        content: Text(isWhiteResigning ? "Qora g'alaba qozondi!" : "Oq g'alaba qozondi!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGameState();
            },
            child: const Text("Yangi o'yin"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white30,
      body: Column(
        children: [
          // Qora o'yinchi uchun resign tugmasi
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Qora",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => resign(false),
                  icon: const Icon(Icons.flag, size: 16),
                  label: const Text("Taslim"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          // Qora o'yinchi o'ldirilgan donalari
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: whitePiecesTaken.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
              itemBuilder: (context, index) => DeadPiece(
                imagePath: whitePiecesTaken[index].imagePath,
                isWhite: true,
              ),
            ), // GridView.builder
          ), // Expanded
          // CHECK holati va Qayta boshlash tugmasi
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (checkStatus)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "SHOH!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Text(
                  isWhiteTurn ? "Oq yuradi" : "Qora yuradi",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: restartGame,
                  icon: const Icon(Icons.refresh),
                  tooltip: "Qayta boshlash",
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8 * 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8),
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;

                bool isSelected = selectedCol == col && selectedRow == row;
                bool isValidMove = false;
                for (var position in validMoves) {
                  // compare row and col
                  if (position[0] == row && position[1] == col) {
                    isValidMove = true;
                  }
                }

                return Square(
                  isValidMove: isValidMove,
                  onTap: () => pieceSelected(row, col),
                  isSelected: isSelected,
                  isWhite: isWhite(index),
                  piece: board[row][col],
                );
              },
            ),
          ),

          // Oq o'yinchi o'ldirilgan donalari
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blackPiecesTaken.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
              itemBuilder: (context, index) => DeadPiece(
                imagePath: blackPiecesTaken[index].imagePath,
                isWhite: false,
              ),
            ), // GridView.builder
          ), // Expanded
          // Oq o'yinchi uchun resign tugmasi
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Oq",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => resign(true),
                  icon: const Icon(Icons.flag, size: 16),
                  label: const Text("Taslim"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
