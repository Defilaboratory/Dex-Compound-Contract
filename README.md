#### DexPro
##### DexPro
A debit and credit protocol based on a modification of Compound that provides debit and credit mining capabilities.

- 整体fork自Compound
- 目录结构：
    - contracts目录，所有用到的原始合约文件
    - solInOne目录, 所有的合约文件通过truffle-flattener进行合并后的单一文件，方便部署和调试
