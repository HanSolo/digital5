class Person {
    var icon, temp, tempMin, tempMax, msg;
                        
    function initialize(icon, temp, tempMin, tempMax, msg) {
        self.icon    = icon;
        self.temp    = temp;
        self.tempMin = tempMin;
        self.tempMax = tempMax;
        self.msg     = msg;
    }
    
    function toString() {
        System.println("\nicon   : " + self.icon + 
                       "\ntemp   : " + self.temp +
                       "\ntempMin: " + self.tempMin +
                       "\ntempMax: " + self.tempMax +
                       "\nmsg    : " + self.msg);
    }
}