
#include "CUDAAI.hpp"
#include "Test.cuh"
using namespace Warped;


void CUDAAI::GetMoves(char *grid, const int gridRows, const int gridColumns, int currentRow, int currentColumn, int currentRotation, TetrisPieces::Piece *currentPiece, vector<TetrisPieces::Piece *> upcomingPieces, vector<Warped::TetrisMove> *moves)
{
    GetCUDAMoves(grid, gridRows, gridColumns, currentRow, currentColumn, currentRotation, currentPiece, upcomingPieces, moves);
//    DoSomethingInCuda(5);
}