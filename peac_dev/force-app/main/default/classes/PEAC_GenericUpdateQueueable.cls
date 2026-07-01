/**
 * Class Name : PEAC_GenericUpdateQueueable
 * Description:
 *  Generic Queueable to perform asynchronous UPDATE operation for any SObject type.
 *  Retries update up to configured attempts when UNABLE_TO_LOCK_ROW occurs.
 *
 * Labels Used:
 *  - PEAC_GenericUpdateQueueable_MAX_RETRIES
 *  - PEAC_GenericUpdateQueueable_WAIT_MILLISECONDS
 *
 * Author: Manish Suwalka
 * Date: 17-03-2026
 */
public class PEAC_GenericUpdateQueueable implements Queueable {

    private final List<SObject> recordsToUpdate;

    public PEAC_GenericUpdateQueueable(List<SObject> recordsToUpdate) {
        this.recordsToUpdate = recordsToUpdate;
    }

    public void execute(QueueableContext context) {

        if (recordsToUpdate == null || recordsToUpdate.isEmpty()) return;

        List<SObject> validRecords = new List<SObject>();
        for (SObject s : recordsToUpdate) {
            if (s != null && s.Id != null) {
                validRecords.add(s);
            }
        }
        if (validRecords.isEmpty()) return;

        Integer maxRetries = Integer.valueOf(
            Label.PEAC_GenericUpdateQueueable_MAX_RETRIES
        );
        Integer waitMillis = Integer.valueOf(
            Label.PEAC_GenericUpdateQueueable_WAIT_MILLISECONDS
        );

        Integer attempt = 0;
        Boolean isSuccess = false;

        while (attempt < maxRetries && !isSuccess) {
            try {
                update validRecords;
                isSuccess = true; //Stop retries on success
            } catch (DmlException ex) {
                System.debug('ERROR ' + ex.getMessage() +' ' + ex.getStackTraceString());
                if (isUnableToLockRowException(ex)) {
                    attempt++;

                    if (attempt >= maxRetries) {
                        throw ex;
                    }

                    //Wait before next retry
                    waitForMilliseconds(waitMillis);
                } else {
                    //Non-locking DML errors should fail immediately
                    throw ex;
                }
            }
        }
    }

    /**
     * Detects UNABLE_TO_LOCK_ROW exception
     */
    public static Boolean isUnableToLockRowException(DmlException ex) {
        return ex.getMessage() != null &&
               ex.getMessage().contains('UNABLE_TO_LOCK_ROW');
    }

    public static void waitForMilliseconds(Integer millis) {
        Long start = DateTime.now().getTime();
        while (DateTime.now().getTime() - start < millis) {
            // intentional no-op
        }
    }
}