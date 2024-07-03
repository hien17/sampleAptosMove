module mint_nft::create_nft_with_resource_account {
    use std::string;
    use std::vector;
    use aptos_token::token;
    use std::signer;
    use std::string::String;
    use aptos_token::token::TokenDataId;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::resource_account;
    use aptos_framework::account;

    /// Declare struct stores an NFT'collection's relavant infomation
    struct ModuleData has key {
        // Store signer capability so module can programmatically sign for transactions
        signer_cap: SignerCapability,
        token_data_id: TokenDataId,
    }

    /// `init_module` is automatically called when publishing module
    /// Create an example NFT collection and an example token
    fun init_module(resource_signer: &signer){
        let collection_name = string::utf8(b"ESOL LABS's collection");
        let description = string::utf8(b"This is a collection created by LUBAN headquarter");
        let collection_uri = string::utf8(b"Collection URI");
        let token_name = string::utf8(b"ESOL TOKEN");
        let token_uri = string::utf8(b"Token URI");

        // The supply of the token will not be tracked
        let maximum_supply = 0;

        // This variable sets if we want to allow mutation for 
        // collection description, uri and maximum
        // Setting all to false means that we don't allow mutations to any CollectionData fields
        let mutate_setting = vector<bool>[false, false, false];

        // Create the nft collection
        token::create_collection(resource_signer, collection_name, description, collection_uri, maximum_supply, mutate_setting);

        // Create a token data id to specified the token to be minted
        let token_data_id = token::create_tokendata(
            resource_signer,
            collection_name,
            token_name,
            string::utf8(b""),
            0,
            token_uri,
            signer::address_of(resource_signer),
            1,
            0,
            // This variable sets if we want allow mutation for token maximum, uri, royalty, description and properties
            // Here we enable mutation for propertes by setting last boolean to true
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            // Use property maps to record attribute related to the token
            // Record user's address
            // Mutate this field to record user's address 
            // when a user successfully mints a token in the `mint_event_ticket()` function
            vector<String>[string::utf8(b"given_to")],
            vector<vector<u8>>[b""],
            vector<String>[ string::utf8(b"address") ],
        );

        // Retrieve the resource signer's signer capability and store it within the `ModuleData`
        // Note that by calling `resource_account::retrieve_resource_account_cap` to retrieve the resource account's signer capability,
        // we rotate the resource account's authentication key to 0 and give up our control over the resource account. Before calling this function,
        // the resource account has the same authentication key as the source account so we had control over the resource account.
        let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);

        move_to(resource_signer, ModuleData {
            signer_cap: resource_signer_cap,
            token_data_id,
        });
    }

    /// Mint an NFT to the receiver. Here we only ask for the receiver's
    /// signer. This is because we used resource account to publish this module and stored the resource account's signer
    /// within the `ModuleData`, so we can programmatically sign for transactions instead of manually signing transactions.
    public entry fun mint_event_ticket(receiver: &signer) acquires ModuleData {
        let module_data = borrow_global_mut<ModuleData>(@mint_nft);

        // Create a signer of the resource account from the signer capability stored in this module.
        // Using a resource account and storing its signer capability within the module allows the module to programmatically
        // sign transactions on behalf of the module.
        let resource_signer = account::create_signer_with_capability(&module_data.signer_cap);
        let token_id = token::mint_token(&resource_signer, module_data.token_data_id, 1);
        token::direct_transfer(&resource_signer, receiver, token_id, 1);

        let (creator_address, collection, name) = token::get_token_data_id_fields(&module_data.token_data_id);
        token::mutate_token_properties(
            &resource_signer,
            signer::address_of(receiver),
            creator_address,
            collection,
            name,
            0,
            1,
            vector::empty<String>(),
            vector::empty<vector<u8>>(),
            vector::empty<String>(),
        );
    }
}