pragma solidity ^0.8.10;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import 'hardhat/console.sol';

import {StringUtils} from './libraries/StringUtils.sol';
import {Base64} from './libraries/Base64.sol';

contract Domains is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;
    mapping(string => address) public domains;
    mapping(string => string) public records;
    mapping(string => string) public avatars;
    mapping(uint256 => string) public names;

    error Unauthorized();
    error AlreadyRegistered();
    error NotEnoughPaid();
    error InvalidName(string name);

    // On chain SVG.
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949a4.382 4.382 0 0 0-4.394 0l-10.081 6.032-6.85 3.934-10.081 6.032a4.382 4.382 0 0 1-4.394 0l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616 4.54 4.54 0 0 1-.608-2.187v-9.31a4.27 4.27 0 0 1 .572-2.208 4.25 4.25 0 0 1 1.625-1.595l7.884-4.59a4.382 4.382 0 0 1 4.394 0l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616 4.54 4.54 0 0 1 .608 2.187v6.032l6.85-4.065v-6.032a4.27 4.27 0 0 0-.572-2.208 4.25 4.25 0 0 0-1.625-1.595L41.456 24.59a4.382 4.382 0 0 0-4.394 0l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595 4.273 4.273 0 0 0-.572 2.208v17.441a4.27 4.27 0 0 0 .572 2.208 4.25 4.25 0 0 0 1.625 1.595l14.864 8.655a4.382 4.382 0 0 0 4.394 0l10.081-5.901 6.85-4.065 10.081-5.901a4.382 4.382 0 0 1 4.394 0l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616 4.54 4.54 0 0 1 .608 2.187v9.311a4.27 4.27 0 0 1-.572 2.208 4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721a4.382 4.382 0 0 1-4.394 0l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616 4.53 4.53 0 0 1-.608-2.187v-6.032l-6.85 4.065v6.032a4.27 4.27 0 0 0 .572 2.208 4.25 4.25 0 0 0 1.625 1.595l14.864 8.655a4.382 4.382 0 0 0 4.394 0l14.864-8.655a4.545 4.545 0 0 0 2.198-3.803V55.538a4.27 4.27 0 0 0-.572-2.208 4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z"><animate attributeName="fill" attributeType="XML" values="#E57547;#8247E5;#E57547" dur="4s" repeatCount="indefinite"/></path><defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#e57547"><animate attributeName="stop-color" values="#8247E5; #e57547;#8247E5" dur="4s" repeatCount="indefinite"/></stop><stop offset="1" stop-color="#8247E5" stop-opacity=".99"><animate attributeName="stop-color" values="#e57547; #8247E5;#e57547" dur="4s" repeatCount="indefinite"/></stop></linearGradient></defs><text x="32.5" y="231" font-size="18" fill="#fff" filter="url(#b)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    constructor(string memory _tld)
        payable
        ERC721('Dance Name Service', 'DNS')
    {
        tld = _tld;
        console.log('%s name service deployed.', _tld);
    }

    modifier onlyDomainOwner(string calldata name) {
        if (domains[name] != msg.sender) revert Unauthorized();
        _;
    }

    function isValid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 20;
    }

    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        if (len <= 0) revert InvalidName(name);
        if (len == 3) {
            return 5 * 10**16; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**16; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**16;
        }
    }

    function register(string calldata name) public payable {
        // Checks that it's not already registered.
        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!isValid(name)) revert InvalidName(name);

        uint256 _price = price(name);

        if (msg.value < _price) revert NotEnoughPaid();

        string memory _name = string(abi.encodePacked(name, '.', tld));
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log(
            'Registering %s.%s on the contract with token ID %d',
            name,
            tld,
            newRecordId
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name,
                        '", "description": "A domain on the Dance name service", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '","length":"',
                        strLen,
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked('data:application/json;base64,', json)
        );

        console.log(
            '\n--------------------------------------------------------'
        );
        console.log('Final tokenURI', finalTokenUri);
        console.log(
            '--------------------------------------------------------\n'
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);

        domains[name] = msg.sender;
        names[newRecordId] = name;
        console.log('%s has registered a domain!', msg.sender);

        _tokenIds.increment();
    }

    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record)
        public
        onlyDomainOwner(name)
    {
        records[name] = record;
    }

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }

    function setAvatar(string calldata name, string calldata record)
        public
        onlyDomainOwner(name)
    {
        avatars[name] = record;
    }

    function getAvatar(string calldata name)
        public
        view
        returns (string memory)
    {
        return avatars[name];
    }

    function updateData(
        string calldata name,
        string calldata record,
        string calldata avatar
    ) public payable {
        setRecord(name, record);
        setAvatar(name, avatar);
    }

    function registerAndSetData(
        string calldata name,
        string calldata record,
        string calldata avatar
    ) public payable {
        register(name);
        updateData(name, record, avatar);
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}('');
        require(success, 'Failed to withdraw matic');
    }

    function getAllNames() public view returns (string[] memory) {
        console.log('Getting all names from contract');
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log('Name for token %d is %s', i, allNames[i]);
        }
        return allNames;
    }
}
