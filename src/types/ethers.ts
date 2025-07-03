import { ethers } from 'ethers'

declare global {
  interface Window {
    ethereum?: ethers.providers.ExternalProvider
  }
}

interface MetaMaskProvider {
  isMetaMask: boolean
  isConnected: () => boolean
  request: (request: { method: string; params?: any[] | undefined }) => Promise<any>
  on: (event: string, callback: (param: any) => void) => void
}

export interface ITodo {
  id: number
  author: string
  message: string
  timestamp: number
}

export class Todo implements ITodo {
  public id: number
  public author: string
  public message: string
  public timestamp: number

  constructor(id: number, author: string, message: string, timestamp: number) {
    this.id = id
    this.author = author
    this.message = message
    this.timestamp = timestamp
  }
}

export const contractAddr = '0x52dC2c1807aF8aAb9F07F0fF0a42332817939698'

export interface AccountProps {
  account: string
}
