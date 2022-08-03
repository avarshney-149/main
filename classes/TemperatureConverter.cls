public class TemperatureConverter {
    // Takes a Fahrenheit temperature and returns the Celsius equivalent.
    public static Decimal FahrenheitToCelsius(Decimal fh) {
        Decimal cs = (fh - 32) * 5/9;
        return cs.setScale(2);
    }
    
<<<<<<< HEAD
<<<<<<< HEAD
    //Test Conflict Res 123
=======
    //Test Conflict not in promo branch
>>>>>>> refs/remotes/origin/feature/US-0008312
=======
    //Test Conflict Res - New page not in promotion branch
>>>>>>> refs/remotes/origin/feature/US-0008340
}