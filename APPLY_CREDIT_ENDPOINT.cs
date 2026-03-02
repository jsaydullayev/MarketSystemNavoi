// Add this method to MarketSystem.API/Controllers/SalesController.cs
// Insert this code after line 104 (after the UpdateSaleCustomer catch block)

    [HttpPost("{saleId}/apply-credit")]
    public async Task<ActionResult<SaleDto>> ApplyCustomerCredit(Guid saleId)
    {
        try
        {
            _logger.LogInformation("=== CONTROLLER: ApplyCustomerCredit called ===");
            _logger.LogInformation("Sale ID: {SaleId}", saleId);

            var sale = await _saleService.ApplyCustomerCreditAsync(saleId);
            if (sale is null)
                return NotFound();

            _logger.LogInformation("=== CONTROLLER: ApplyCustomerCredit SUCCESS ===");
            return Ok(sale);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogError(ex, "Error applying customer credit");
            return BadRequest(ex.Message);
        }
    }
