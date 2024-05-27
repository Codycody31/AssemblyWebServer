# Jump Instructions

| Instruction            | Description                                                      | Signed-ness | Conditions checked           |
| ---------------------- | ---------------------------------------------------------------- | ----------- | ---------------------------- |
| JO                     | Jump if overflow                                                 |             | OF = 1                       |
| JNO                    | Jump if not overflow                                             |             | OF = 0                       |
| JS                     | Jump if sign                                                     |             | SF = 1                       |
| JNS                    | Jump if not sign                                                 |             | SF = 0                       |
| JE<br>JZ               | Jump if equal<br>Jump if zero                                    |             | ZF = 1                       |
| JNE<br>JNZ             | Jump if not equal<br>Jump if not zero                            |             | ZF = 0                       |
| JP<br>JPE              | Jump if parity<br>Jump if parity even                            |             | PF = 1                       |
| JNP<br>JPO             | Jump if no parity<br>Jump if parity odd                          |             | PF = 0                       |
| JCXZ<br>JECXZ<br>JRCXZ | Jump if CX is zero<br>Jump if ECX is zero<br>Jump if RCX is zero |             | CX = 0<br>ECX = 0<br>RCX = 0 |
|                        |                                                                  |             |                              |
| JB<br>JNAE<br>JC       | Jump if below<br>Jump if not above or equal<br>Jump if carry     | unsigned    | CF = 1                       |
| JNB<br>JAE<br>JNC      | Jump if not below<br>Jump if above or equal<br>Jump if not carry | unsigned    | CF = 0                       |
| JBE<br>JNA             | Jump if below or equal<br>Jump if not above                      | unsigned    | CF = 1 or ZF = 1             |
| JA<br>JNBE             | Jump if above<br>Jump if not below or equal                      | unsigned    | CF = 0 and ZF = 0            |
|                        |                                                                  |             |                              |
| JL<br>JNGE             | Jump if less<br>Jump if not greater or equal                     | signed      | SF <> OF                     |
| JGE<br>JNL             | Jump if greater or equal<br>Jump if not less                     | signed      | SF = OF                      |
| JLE<br>JNG             | Jump if less or equal<br>Jump if not greater                     | signed      | ZF = 1 or SF <> OF           |
| JG<br>JNLE             | Jump if greater<br>Jump if not less or equal                     | signed      | ZF = 0 and SF = OF           |
