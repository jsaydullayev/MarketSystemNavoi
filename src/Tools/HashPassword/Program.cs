using System;

namespace MarketSystem.Tools.HashPassword;

class Program
{
    static void Main(string[] args)
    {
        string password = args.Length > 0 ? args[0] : "jaxongir2005";
        string hash = BCrypt.Net.BCrypt.HashPassword(password);
        Console.WriteLine(hash);
    }
}
