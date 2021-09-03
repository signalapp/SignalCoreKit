//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

// The block is executed immediately if called from the
// main thread; otherwise it is dispatched async to the
// main thread.
void DispatchMainThreadSafe(dispatch_block_t block);

// The block is executed immediately if called from the
// main thread; otherwise it is dispatched sync to the
// main thread.
void DispatchSyncMainThreadSafe(dispatch_block_t block);

dispatch_queue_t DispatchCurrentQueue(void);

NS_ASSUME_NONNULL_END
