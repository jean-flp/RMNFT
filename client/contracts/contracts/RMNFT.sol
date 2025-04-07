// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ReceitasNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Pausable, AccessControl, ERC721Burnable {
    bytes32 public constant MEDIC_ROLE = keccak256("MEDIC_ROLE");
    bytes32 public constant PHARMACY_ROLE = keccak256("PHARMACY_ROLE");
    bytes32 public constant PACIENT_ROLE = keccak256("PACIENT_ROLE");

    uint256 private _nextTokenId;

    constructor(address defaultAdmin)
        ERC721("ReceitasMedicasNFT", "RMNFT")
    {
        //, address pauser, address minter
        //DEFAULT_ADMIN>MEDICO>PACIENTE
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        
        _setRoleAdmin(MEDIC_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PHARMACY_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PACIENT_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    //mandar a URI, retorno com tokenID pensar no que fazer com URI+tokeID
    function safeMint(address to, string memory uri)
        public
        onlyRole(MEDIC_ROLE)
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function _transferToPacient(address from, address to, uint256 tokenId) 
        external
        onlyRole(MEDIC_ROLE){
        require(ownerOf(tokenId) == from, "NAO E O DETENTOR DA TOKEN");
        require(tx.origin == msg.sender, "NAO PODE UTILIZAR UMA CONTRATO INTERMEDIARIO");
        if(_isPharmacy(to)){
            revert("VENDA CASADA, NAO SEJA FURA OLHO, PROCURE UMA VENDA SOLTEIRA");
        }
        if(!_isPacient(to)){
            if(!_isMedic(to)){
                revert("USE SUA CONTA PACIENTE");
            }
            require(hasRole(DEFAULT_ADMIN_ROLE, to) == true,"ADMIN UTILIZE OUTRA FUNCAO PARA TRANSFERENCIA" );
            _grantRole(PACIENT_ROLE,to);
        }
        safeTransferFrom(from, to, tokenId);
    
    }
     function _transferToPharmacy(address from, address to, uint256 tokenId) 
        external
        onlyRole(PACIENT_ROLE){
        require(ownerOf(tokenId) == from, "NAO E O DETENTOR DA TOKEN");
        require(tx.origin == msg.sender, "NAO PODE UTILIZAR UMA CONTRATO INTERMEDIARIO");

        safeTransferFrom(from, to, tokenId);
    }
    function burn(uint256 tokenId) public override (ERC721Burnable) 
    {
        if(_isAdmin(msg.sender)){
            super.burn(tokenId);
        }else if(_isMedic(msg.sender)){ 
            //MEDICO DEVERIA PODER QUEIMAR APENAS A TOKEN QUE ELE DISTRIBUIU AOS PACIENTES E NAO DE OUTROS MEDICOS;
            super.burn(tokenId);
        }else if(_isPacient(msg.sender)){
            require(ownerOf(tokenId) == msg.sender,"NAO PODER DESTRUIR TOKEN DE OUTRO PACIENTE");
            super.burn(tokenId);
        }else if(_isPharmacy(msg.sender)){
            super.burn(tokenId);
        }else{
            revert("NAO HA PERMISSAO PARA EXECUCAO DESTA FUNCAO");
        }
        
    }
    function removeAcessRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE){

        if(_isPharmacy(account)){
            revokeRole(PHARMACY_ROLE, account);
        }else if(_isMedic(account)){ 
            revokeRole(MEDIC_ROLE, account);
        }else{
            revokeRole(PACIENT_ROLE, account);
        }
      
    }
    function _isPacient(address account) public virtual view returns(bool) {
        return hasRole(PACIENT_ROLE,account);
    }
    function _isPharmacy(address account) public virtual view returns(bool) {
        return hasRole(PHARMACY_ROLE,account);
    }
    function _isMedic(address account) public virtual view returns(bool) {
        return hasRole(MEDIC_ROLE,account);
    }
    function _isAdmin(address account) public virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE,account);
    }
    
}