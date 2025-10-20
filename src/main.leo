import workshop_ofac.aleo;

program marintd2809.aleo {
    // Public balances
    mapping balances: address => u64;

    // Private token record schema
    record Token {
        owner: address,
        amount: u64,
    }

    @noupgrade
    async constructor() {}

    // ----------------------------
    // TASK 1: Mint (Public)
    // ----------------------------
    async transition mint_public(
        public recipient: address,
        public amount: u64
    ) -> Future {
        let address_check: Future = workshop_ofac.aleo/address_check(recipient);
        return self.mint_public_onchain(recipient, amount, address_check);
    }

    async function mint_public_onchain(
        public recipient: address,
        public amount: u64,
        public address_check: Future
    ) {
        address_check.await();

        // read old (defaults to 0 if unset)
        let old: u64 = balances.get(recipient);
        let new: u64 = old + amount;

        balances.set(recipient, new);
    }

    // ----------------------------
    // TASK 2: Mint (Private)
    // ----------------------------
    async transition mint_private(
        private recipient: address,
        private amount: u64
    ) -> (Token, Future) {
        let address_check: Future = workshop_ofac.aleo/address_check(recipient);

        // produce a private Token record for recipient
        let token: Token = Token {
            owner: recipient,
            amount: amount,
        };

        let f: Future = self.mint_private_onchain(address_check);
        return (token, f);
    }

    async function mint_private_onchain(
        address_check: Future
    ) {
        address_check.await();
        // no public state change here; just compliance gate
    }

    // ----------------------------
    // TASK 3: Transfer (Public)
    // ----------------------------
    async transition transfer_public(
        public recipient: address,
        public amount: u64
    ) -> Future {
        let address_check: Future = workshop_ofac.aleo/address_check(recipient);
        // self.signer = public sender
        return self.transfer_public_onchain(self.signer, recipient, amount, address_check);
    }

    async function transfer_public_onchain(
        public sender: address,
        public recipient: address,
        public amount: u64,
        public address_check: Future
    ) {
        address_check.await();

        // debit sender
        let sender_old: u64 = balances.get(sender);
        assert(sender_old >= amount);
        let sender_new: u64 = sender_old - amount;
        balances.set(sender, sender_new);

        // credit recipient
        let rcpt_old: u64 = balances.get(recipient);
        let rcpt_new: u64 = rcpt_old + amount;
        balances.set(recipient, rcpt_new);
    }

    // ----------------------------
    // TASK 4: Transfer (Private)
    // ----------------------------
    async transition transfer_private(
        private sender: Token,
        private recipient: address,
        private amount: u64
    ) -> (Token, Token, Future) {
        // consume sender record and split into (to recipient) + (change)
        assert(sender.amount >= amount);

        let address_check: Future = workshop_ofac.aleo/address_check(recipient);

        let to_recipient: Token = Token {
            owner: recipient,
            amount: amount,
        };

        let change: Token = Token {
            owner: sender.owner,
            amount: sender.amount - amount,
        };

        let f: Future = self.transfer_private_onchain(address_check);
        return (to_recipient, change, f);
    }

    async function transfer_private_onchain(
        public address_check: Future
    ) {
        address_check.await();
        // no public state change; just compliance gate for the private flow
    }

    // (Bonus tasks not implemented)
}
