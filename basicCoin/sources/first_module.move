module 0xCAFE::basic_coin {
    struct Coin has key {
        value: u64,
    }

    public fun mint(account: &signer, value: u64) {
        move_to(account, Coin {value})
    }

    // Declare a uint test. It takes a signer called `account` with an
    // address value of '@0xCOFFEE'
    #[test(account = @0xC0FFEE)]
    fun test_mint_10(account: &signer) acquires Coin {
        let addr = 0x1::signer::address_of(account);
        mint(account, 10);
        // Make sure there is a 'Coin' resource under addr with a value of '10'
        // We can access this resourc and it's value since we are in the 
        // same module that defined the 'Coin' resource
        assert!(borrow_global<Coin>(addr).value == 10, 0);
    }
    
    #[test(account = @0xC0FFEE)]
    #[expected_failure]
    fun test_mint_10_should_fail(account: &signer) acquires Coin {
        let addr = 0x1::signer::address_of(account);
        mint(account, 10);
        // Make sure there is a 'Coin' resource under addr with a value of '10'
        // We can access this resourc and it's value since we are in the 
        // same module that defined the 'Coin' resource
        assert!(borrow_global<Coin>(addr).value == 11, 0);
    }
}