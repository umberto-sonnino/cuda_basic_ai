# cuda_basic_ai

This is the basic skeleton for my Bachelor Thesis:
a game of Tetris has been used as a framwork for implementing an AI that performed a series of steps to play the game by itself.
The code was run in parallel inside the framework (which is not open source and thus not available to the public), but the code ran in parallel as of 2012. 
The idea behind the algorithm was to exploit a Monte-Carlo Tree Search that was run in parallel, for every node at every level, so that the performance bump could be exploited especially as the computational tree grew. 
The Tree in the computation was a series of tests that the program had to perform in order to choose the best move to create a good configuration of the tetris grid. Through a reward system based on points (with bonuses and maluses) the best move could be evaluated once the whole tree had been built.

The case-study was very interesting both for its implications in programming but also for the thourough analysis that I had to conduct in order to understand how CUDA actually works at the machine level. 
