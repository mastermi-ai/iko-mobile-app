import 'package:workmanager/workmanager.dart';
import 'sync_service.dart';

// Task identifiers
const String periodicSyncTask = 'com.iko.periodicSync';
const String oneTimeSyncTask = 'com.iko.oneTimeSync';

/// Initialize background worker
Future<void> initializeBackgroundWorker() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Register periodic sync task (every 15 minutes)
  await Workmanager().registerPeriodicTask(
    periodicSyncTask,
    periodicSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}

/// Cancel all background tasks
Future<void> cancelAllBackgroundTasks() async {
  await Workmanager().cancelAll();
}

/// Request immediate one-time sync
Future<void> requestImmediateSync() async {
  await Workmanager().registerOneOffTask(
    'oneTimeSync_${DateTime.now().millisecondsSinceEpoch}',
    oneTimeSyncTask,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}

/// Background task callback dispatcher
/// This function MUST be top-level (not inside a class)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case periodicSyncTask:
          // Periodic full sync
          await SyncService.instance.performFullSync();
          break;

        case oneTimeSyncTask:
          // One-time quick sync
          await SyncService.instance.quickSync();
          break;

        default:
          // Unknown task - try quick sync
          await SyncService.instance.quickSync();
      }
      return true;
    } catch (e) {
      // Task failed - will retry on next scheduled run
      return false;
    }
  });
}
