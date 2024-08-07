/*
    Copyright © 2024, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna the Foxgirl
*/

module inochi2d.core.cqueue;
import inochi2d.core.commands;
import numem.all;

/**
    Command queue which rendering commands are submitted to by the Inochi2D runtime.

    Backends should consume the commands in the queue to render a frame.
*/
class CommandQueue {
@nogc:
private:
    bool isBegun = false;
    size_t ridx = 0;
    vector!RenderCommand queue;

public:

    /**
        Begins command submission
    */
    void begin() {
        if (!isBegun) {
            queue.clear();
            ridx = 0;
            isBegun = true;
        }
    }

    /**
        Submits a command to the queue.
    */
    void submit(RenderCommand command) {
        assert(isBegun, "Attempted to submit a command into a queue which wasn't ready!");
        queue ~= command;
    }

    /**
        Ends command submission and verifies commands.
    */
    void end() {
        if (isBegun) {
            isBegun = false;
            // TODO: Verify commands.
        }
    }

    /**
        Compacts the command queue
    */
    void compact() {
        queue.shrinkToFit();
    }

    /**
        Gets the next command in the queue.

        This should be called in a tight loop by the renderer to update meshes, etc.
    */
    RenderCommand* next() {
        if (ridx >= queue.size) return null;
        return &queue[ridx++];
    }
}