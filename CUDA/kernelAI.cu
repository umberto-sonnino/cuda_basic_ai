#include "CUDAAI.hpp"
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include "kernelAI.cuh"

using namespace Warped;

const double MIN_SCORE = -99999999;
template <class T>

struct KernelArray
{
    T* array;
    int size;
};

struct Result
{
    double Score;
    int Rotation;
    int Column;
};

__global__ void parallelBest(char* grid, int rows, int columns, TetrisPieces::Piece* piece, KernelArray<TetrisPieces::Piece*> upcomingPieces, int nextPieceIndex, Result *result, int mutex)
{
    //thread 1 accesses 1st element of the vector, thread 2 accesses 2nd element and so on
    
    int idx = threadIdx.x;


    if(idx < upcomingPieces.size)
    {
        double wtouch = 0;
        double wheight = 0;
        double wholes = 0;
        double wlines = 0;
        
        TetrisPieces::Piece::Definition* def = piece->GetDefinition(idx) ;
        
        for(int c = 0; c < columns; c++)
        {
            // Find collision point on this column.
            
            int collisionRow = -1;
            bool overflow = false;
            for(int r = 0; r <= rows; r++)
            {
                for(int pr = 0; pr < def->Rows; pr++)
                {
                    for(int pc = 0; pc < def->Columns; pc++)
                    {
                        if(def->Grid[pr*def->Columns+pc])
                        {
                            int gcc = c + pc;
                            int gcr = r + pr;
                            if(gcc >= columns)
                            {
                                overflow = true;
                                break;
                                continue;
                            }
                            else if(gcr >= rows || grid[gcr*columns+gcc] != -1)
                            {
                                collisionRow = r;
                                break;
                            }
                        }
                    }
                    if(collisionRow != -1)
                    {
                        break;
                    }
                }
                
                if(collisionRow != -1)
                {
                    break;
                }
            }
            
            // Found where this piece will collide on this column.
            // Determine score by lines cleared.
            collisionRow -= 1;
            
            int holesCreated = 0;
            if(collisionRow != -1 && !overflow)
            {
                double touch = 0;
                double height = 0;
                double holes = 0;
                double lines = 0;
                
                char scratchGrid[200];
                memcpy(scratchGrid, grid, rows*columns);
                char preclearGrid[200];

                
                // Commit to scratch.
                for(int pr = 0; pr < def->Rows; pr++)
                {
                    for(int pc = 0; pc < def->Columns; pc++)
                    {
                        if(def->Grid[pr*def->Columns+pc])
                        {
                            scratchGrid[(collisionRow+pr)*columns+pc+c] = 1;
                        }
                    }
                }
                                
                memcpy(preclearGrid, scratchGrid, rows*columns);

                // Check holes created
                for(int pr = 0; pr < def->Rows; pr++)
                {
                    for(int pc = 0; pc < def->Columns; pc++)
                    {
                        if(def->Grid[pr*def->Columns+pc])
                        {
                            for(int cd = collisionRow+pr+1; cd < rows; cd++)
                            {
                                if(scratchGrid[cd*columns+pc+c] == -1)
                                {
                                    holesCreated++;
                                }
                                else
                                {
                                    break;
                                }
                            }
                        }
                    }
                }
                
                // Points based on empty blocks and lines cleared.
                double positionScore = 0;//collisionRow;
                int fills = 0;
                int firstRowFill = -1;

                for(int psr = 0; psr < rows; psr++)
                {
                    for(int psc = 0; psc < columns; psc++)
                    {
                        if(scratchGrid[psr*Tetris::GridWidth+psc] != -1)
                        {
                            if(firstRowFill == -1)
                            {
                                firstRowFill = psr;
                            }
                            fills++;
                            if(psc < columns-1)
                            {
                                if(scratchGrid[psr*Tetris::GridWidth+psc+1] != -1)
                                {
                                    touch+=10;
                                }
                            }
                            if(psr == Tetris::GridHeight-1)
                            {
                                touch+=20;
                            }
                            else if(scratchGrid[(psr+1)*Tetris::GridWidth+psc] != -1)
                            {
                                touch+=10;
                            }
                        }
                    }
                }
                height = (Tetris::GridHeight-firstRowFill)*-3.5;//((double)fills/(Tetris::GridHeight-firstRowFill))*-10.0;///2.0;
                holes = holesCreated*-15.0;

                // Count lines cleared.
                int linesCleared = 0;
                for(int cr = Tetris::GridHeight-1; cr >= 0; cr--)
                {
                    int lineHasEmpty = false;
                    for(int cc = 0; cc < Tetris::GridWidth; cc++)
                    {
                        if(scratchGrid[cr*Tetris::GridWidth+cc] == -1)
                        {
                            lineHasEmpty = true;
                            break;
                        }
                    }
                    
                    // Did any lines get cleared?
                    if(!lineHasEmpty)
                    {
                        // Bump the lines above.
                        for(int kr = cr-1; kr >= 0; kr--)
                        {
                            for(int cc = 0; cc < Tetris::GridWidth; cc++)
                            {
                                scratchGrid[(kr+1)*Tetris::GridWidth+cc] = scratchGrid[kr*Tetris::GridWidth+cc];
                            }
                        }
                        
                        // Clear out top row.
                        for(int cc = 0; cc < Tetris::GridWidth; cc++)
                        {
                            scratchGrid[cc] = -1;
                        }
                        
                        // Repeat this row since we cleared it.
                        cr++;
                        
                        linesCleared++;
                    }
                }
                
                lines = linesCleared*55.0;
                positionScore = touch+height+holes+lines;
                                
                // See what the best of the rest is.
               if(false)
               {
                Result nextResult;
                nextResult.Score = MIN_SCORE;
                nextResult.Rotation = 0;
                nextResult.Column = 0;
                //1 thread for each node in the next leve of the tree.
                int numThreads = upcomingPieces.array[nextPieceIndex]->GetRotations();
                if(nextPieceIndex < upcomingPieces.size)
                {
                    int nextMutex = 0;
                    parallelBest<<<1, numThreads >>>(scratchGrid, rows, columns, upcomingPieces.array[nextPieceIndex], upcomingPieces, nextPieceIndex+1, &nextResult, nextMutex);
                }
                __syncthreads();
                while(mutex != 0);//wait
                mutex = 1;
                if(positionScore + nextResult.Score > result->Score)
                {
                    result->Score = positionScore + nextResult.Score;
                    result->Rotation = idx;
                    result->Column = c;
                }
               }
               else{
                if(positionScore > result->Score)
                {
                    
                    wtouch = touch;
                    wheight = height;
                    wholes = holes;
                    wlines = lines;
                    
                    result->Score = positionScore;
                    result->Rotation = idx;
                    result->Column = c;
                }
                mutex = 0;
               }
            }
            
        }
    }
}


extern void GetCUDAMoves(char* grid, const int gridRows, const int gridColumns, int currentRow, int currentColumn, int currentRotation, 
    TetrisPieces::Piece* currentPiece, std::vector<TetrisPieces::Piece*> upcomingPieces, std::vector<TetrisMove> *moves)
{
    static char scratchGrid[Tetris::GridWidth*Tetris::GridHeight];
    memcpy(scratchGrid, grid, gridRows*gridColumns);
    
    Result result;
    result.Score = MIN_SCORE;
    result.Rotation = 0;
    result.Column = 0;
    KernelArray<TetrisPieces::Piece*> kernel_Array;
    
    kernel_Array.array = (TetrisPieces::Piece**) malloc(sizeof(TetrisPieces::Piece)*upcomingPieces.size());
    kernel_Array.size = upcomingPieces.size();
    
    for(int i = 0; i < upcomingPieces.size(); i++)
    {
        TetrisPieces::Piece* piece = upcomingPieces[i];
        kernel_Array.array[i] = piece;
        
    }
    //1 thread for every rotation & ~1 block for every piece, since 4 max rotations on any piece
    int numThreads = currentPiece->GetRotations();
    
    
    char *deviceGrid;
    cudaMalloc(&deviceGrid, gridRows*gridColumns);   
    cudaMemcpy(deviceGrid, (void*)grid, gridRows*gridColumns, cudaMemcpyHostToDevice);

    Result *deviceResult;
    cudaMalloc(&deviceResult, sizeof(result));
    cudaMemcpy(deviceResult, (void*)&result, sizeof(result), cudaMemcpyHostToDevice);

    TetrisPieces::Piece *devicePiece;
    cudaMalloc(&devicePiece, sizeof(currentPiece));
    cudaMemcpy(devicePiece, (void*)currentPiece, sizeof(currentPiece), cudaMemcpyHostToDevice);

    parallelBest <<<1, numThreads>>> (deviceGrid, gridRows, gridColumns, devicePiece, kernel_Array, 0, deviceResult, 0);

    
    result.Rotation = deviceResult->Rotation;
    result.Column = deviceResult->Column;
    result.Score = deviceResult->Score;

    // Do rotation moves.
    int r = currentRotation;
    while(r != result.Rotation)
    {
        moves->push_back(TetrisMove(TetrisMoveType(6)/*::RotateRight*/));
        r = (r+1)%currentPiece->GetRotations();
    }
  
    // Do column moves.
    while(currentColumn < result.Column)
    {
        moves->push_back(TetrisMove(TetrisMoveType(1)/*::MoveRight*/));
        currentColumn++;
    }
    while(currentColumn > result.Column)
    {
        moves->push_back(TetrisMove(TetrisMoveType(0)/*::MoveLeft*/));
        currentColumn--;
    }
    
    moves->push_back(TetrisMove(TetrisMoveType(4)/*::SlamDown*/));
}