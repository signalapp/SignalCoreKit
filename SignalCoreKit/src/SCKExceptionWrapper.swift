//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

import Foundation

extension SCKExceptionWrapper {

    // If the tryBlock hits an exception, the exception is caught and logged
    // If the optional errorBlock is provided, it is invoked before rethrowing to give
    // the caller a chance to log additional information.
    // Finally, once all logs have been flushed, the exception is rethrown up the stack.
    public static func perform(
        label: String,
        _ tryBlock: () -> Void,
        errorBlock: (() -> Void)? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        SCKExceptionWrapper.__exceptionLogger(
            withLabel: label,
            file: file,
            function: function,
            line: line,
            block: tryBlock,
            errorBlock:errorBlock)
    }
}
