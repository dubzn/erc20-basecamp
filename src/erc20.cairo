#[contract]
mod ERC20 {
    use starknet::get_caller_address;
    use integer::u256;
    const ZERO_FELT: felt = 0;

    struct Storage {
        name: felt, 
        symbol: felt,
        decimals: u8,
        total_supply: u256,
        balances: LegacyMap::<felt, u256>,
        allowances: LegacyMap::<(felt, felt), u256>,
    }

    #[event]
    fn Transfer(_from: felt, _to: felt, _value: u256) {}
    
    #[event]
    fn Approval(_owner: felt, _spender: felt, _value: u256) {}

    #[constructor]
    fn init(name: felt, symbol: felt, decimals: u8, initial_supply: u256, recipent: felt) {
        assert(decimals < 100_u8, 'ERC20: decimals exceed 2^8');
        name::write(name);
        symbol::write(symbol);
        decimals::write(decimals);
        assert(recipent != 0, 'ERC20: mint to the zero address');
        mint(recipent, initial_supply);
    }

    #[view]
    fn get_name() -> felt {
        name::read()
    }

    #[view]
    fn get_symbol() -> felt {
        symbol::read()
    }

    #[view]
    fn get_decimals() -> u8 {
        decimals::read()
    }

    #[view]
    fn get_total_supply() -> u256 {
        total_supply::read()
    }

    #[view]
    fn balance_of(account: felt) -> u256 {
        balances::read(account)
    }

    #[external]
    fn transfer(_to: felt, value: u256) {
        let sender = get_caller_address();
        assert(_to != ZERO_FELT, 'ERC20: cannot transfer to the zero address');
        assert(sender != ZERO_FELT, 'ERC20: cannot transfer from the zero address');
        
        balances::write(_to, balances::read(_to) + value);
        balances::write(sender, balances::read(sender) - value);
        Transfer(sender, _to, value);
    }

    #[external]
    fn transfer_from(_from: felt, _to: felt, _value: u256) {
        let sender = get_caller_address();
        assert(_to != ZERO_FELT, 'ERC20: cannot transfer to the zero address');
        assert(_from != ZERO_FELT, 'ERC20: cannot transfer from the zero address');

        let allowance = allowances::read((_from, sender));
        let new_amount = allowance - _value;
        assert(new_amount < u256_from_felt(0), 'ERC20: transfer amount exceeds balance');

        allowances::write((_from, sender), new_amount);
        balances::write(_to, balances::read(_to) + _value);
        balances::write(_from, balances::read(_from) - _value);
        
        Transfer(_from, _to, _value);
    }

    #[external]
    fn mint(account: felt, amount: u256) {
        balances::write(account, balances::read(account) + amount);
        total_supply::write(total_supply::read() + amount);
        Transfer(ZERO_FELT, account, amount);
    }

    #[external]
    fn approve(account: felt, amount: u256) {
        let caller = get_caller_address();
        allowances::write((caller, account), amount);
        Approval(caller, account, amount);
    }
}