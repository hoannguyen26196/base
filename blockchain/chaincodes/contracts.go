package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)


type Contract struct {
	contractapi.Contract
}

func (c *Contract) Init(ctx contractapi.TransactionContextInterface, params string) {
}
