//
//  CUDAAI.hpp
//  Warped
//
//  Created by Umberto Sonnino on 11/21/12.
//  Copyright (c) 2012 SplitCell. All rights reserved.
//

#ifndef Warped_CUDAAI_hpp
#define Warped_CUDAAI_hpp

#ifndef _VECTOR_H
#include <vector>
#endif

#ifndef __Warped__Tetris__
#include "../Tetris.hpp"
#endif

#ifndef __Warped__TetrisPieces__Piece__
#include "../Piece.hpp"
#endif


#ifndef __Warped__AIBase__
#include "../AI/AIBase.hpp"
#endif

#ifndef Warped_kernelAI
#include "kernelAI.cuh"
#endif

namespace Warped
{
    class CUDAAI : public AIBase
    {
    public:
        void GetMoves(char* grid, const int gridRows, const int gridColumns, int currentRow, int currentColumn, int currentRotation, TetrisPieces::Piece* currentPiece, vector<TetrisPieces::Piece*> upcomingPieces, vector<TetrisMove> *moves);
    };
}
#endif
