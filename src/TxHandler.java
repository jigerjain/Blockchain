import java.util.HashSet;
import java.util.List;
import java.util.stream.Collectors;



public class TxHandler {

    // Defined a private utxoPool for class usage of Unused transaction pool
    private final UTXOPool utxoPool;

    /**
     * Creates a public ledger whose current UTXOPool (collection of unspent
     * transaction outputs) is {@code utxoPool}. This should make a copy of utxoPool
     * by using the UTXOPool(UTXOPool uPool) constructor.
     */
    public TxHandler(UTXOPool utxoPool) {
        // IMPLEMENT THIS
        this.utxoPool = new UTXOPool(utxoPool);
    }

    /**
     * @return true if: (1) all outputs claimed by {@code tx} are in the current
     *         UTXO pool, (2) the signatures on each input of {@code tx} are valid,
     *         (3) no UTXO is claimed multiple times by {@code tx}, (4) all of
     *         {@code tx}s output values are non-negative, and (5) the sum of
     *         {@code tx}s input values is greater than or equal to the sum of its
     *         output values; and false otherwise.
     */
    public boolean isValidTx(Transaction tx) {
        // IMPLEMENT THIS
        // Get a list of all the transactions in transactions list from input stream
        final List<UTXO> transactions = tx.getInputs().stream()
                .map(input -> new UTXO(input.prevTxHash, input.outputIndex)).collect(Collectors.toList());
        return checkAllOutputs(transactions) && iaSignatureValid(tx) && isOutputValuePositive(tx)
                && areUTXOsUnique(tx, transactions) && sumCheck(tx, transactions);
    }

    /**
     * Handles each epoch by receiving an unordered array of proposed transactions,
     * checking each transaction for correctness, returning a mutually valid array
     * of accepted transactions, and updating the current UTXO pool as appropriate.
     */
    public Transaction[] handleTxs(Transaction[] possibleTxs) {
        // IMPLEMENT THIS
        HashSet<Transaction> acceptedTxs = new HashSet<>();

        // checking each transaction for correctness
        for (Transaction tx : possibleTxs)
            if (isValidTx(tx)) {

                acceptedTxs.add(tx);

                // updating the current UTXO pool as appropriate
                for (Transaction.Input input : tx.getInputs())
                    utxoPool.removeUTXO(new UTXO(input.prevTxHash, input.outputIndex));
                int index = 0;
                for (Transaction.Output output : tx.getOutputs())
                    utxoPool.addUTXO(new UTXO(tx.getHash(), index++), output);

            }

        // returning a mutually valid array of accepted transactions
        return acceptedTxs.toArray(new Transaction[acceptedTxs.size()]);


    }

    private boolean checkAllOutputs(final List<UTXO> transactions) {
        // Check if the list of transactions parsed are present in the utxoPool
        return transactions.stream().allMatch(utxoPool::contains);
    }

    private boolean iaSignatureValid(final Transaction tx) {

        for (int i = 0; i < tx.numInputs(); i++) {
            Transaction.Input input = tx.getInput(i);
            UTXO utxo = new UTXO(input.prevTxHash, input.outputIndex);
            if (!Crypto.verifySignature(utxoPool.getTxOutput(utxo).address, tx.getRawDataToSign(i), input.signature))
                return false;
        }
        return true;
    }

    private boolean isOutputValuePositive(final Transaction tx) {
        // Simple Check if the object of output has a value greater than or equal to 0.
        return tx.getOutputs().stream().allMatch(output -> output.value >= 0);
    }

    private boolean areUTXOsUnique(final Transaction tx, final List<UTXO> transactions) {
        // For unique count we just utilize the list of transactions parsed and compare its distinct count with number of transaction counts
        final Long uniqueUTXOsCount = transactions.stream().distinct().count();
        return tx.numInputs() == uniqueUTXOsCount;
    }

    private boolean sumCheck(final Transaction tx, final List<UTXO> transactions) {
        final Double sumInputValues = transactions.stream().map(utxo -> utxoPool.getTxOutput(utxo).value).reduce(0.0, Double::sum);
        final Double sumOutputValues = tx.getOutputs().stream().map(output -> output.value).reduce(0.0, Double::sum);

        return sumInputValues >= sumOutputValues;
    }
}   


