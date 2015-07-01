
#ifndef Warped_kernelAI
#define Warped_kernelAI

#ifndef _VECTOR_H
#include <vector>
#endif

#ifndef __Warped__Tetris__
#include "../Tetris.hpp"
#endif

#ifndef __Warped__TetrisPieces__Piece__
#include "../Piece.hpp"
#endif


extern void GetCUDAMoves(char* grid, const int gridRows, const int gridColumns, int currentRow, int currentColumn, int currentRotation,
                          Warped::TetrisPieces::Piece* currentPiece, std::vector<Warped::TetrisPieces::Piece*> upcomingPieces, std::vector<Warped::TetrisMove> *moves);


#endif
