// Bakeoff #3 - Escrita de Texto em Smartwatches
// IPM 2019-20, Semestre 2
// Entrega: exclusivamente no dia 22 de Maio, até às 23h59, via Discord

// Processing reference: https://processing.org/reference/

import java.util.Arrays;
import java.util.Collections;
import java.util.Random;
import java.util.*;

// Screen resolution vars;
float PPI, PPCM;
float SCALE_FACTOR;

// Finger parameters
PImage fingerOcclusion;
int FINGER_SIZE;
int FINGER_OFFSET;

// Arm/watch parameters
PImage arm;
int ARM_LENGTH;
int ARM_HEIGHT;

// Arrow parameters
PImage leftArrow, rightArrow, checkIcon;
int ARROW_SIZE;
float buttonWidth, buttonHeight;

// Study properties
String[] phrases;                   // contains all the phrases that can be tested
String[] dictionary; 
int NUM_REPEATS            = 2;     // the total number of phrases to be tested
int currTrialNum           = 0;     // the current trial number (indexes into phrases array above)
String currentPhrase       = "";    // the current target phrase
String currentTyped        = "";    // what the user has typed so far
int currentComplete         = 0;
char currentLetter         = 'a';
String currentWord         = "";
String currentPrediction = "";
char letterHover = 'a';
HashMap<Character, ArrayList<String>> m = new HashMap();
String[] typed = new String[NUM_REPEATS];


// Performance variables
float startTime            = 0;     // time starts when the user clicks for the first time
float finishTime           = 0;     // records the time of when the final trial ends
float lastTime             = 0;     // the timestamp of when the last trial was completed
float lettersEnteredTotal  = 0;     // a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0;     // a running total of the number of letters expected (correct phrases)
float errorsTotal          = 0;     // a running total of the number of errors (when hitting next)

//Setup window and vars - runs once
void setup()
{
  //size(900, 900);
  fullScreen();
  textFont(createFont("Arial", 24));  // set the font to arial 24
  noCursor();                         // hides the cursor to emulate a watch environment
  
  // Load images
  arm = loadImage("arm_watch.png");
  fingerOcclusion = loadImage("finger.png");
  leftArrow = loadImage("left.png");
  rightArrow = loadImage("right.png");
  checkIcon = loadImage("check.png");
  
  // Load phrases
  phrases = loadStrings("phrases.txt");                       // load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases), new Random());  // randomize the order of the phrases with no seed
  
  // Scale targets and imagens to match screen resolution
  SCALE_FACTOR = 1.0 / displayDensity();          // scale factor for high-density displays
  String[] ppi_string = loadStrings("ppi.txt");   // the text from the file is loaded into an array.
  PPI = float(ppi_string[1]);                     // set PPI, we assume the ppi value is in the second line of the .txt
  PPCM = PPI / 2.54 * SCALE_FACTOR;               // do not change this!
  buttonWidth = 1.33 * PPCM;
  buttonHeight = 0.75 * PPCM;
  FINGER_SIZE = (int)(11 * PPCM);
  FINGER_OFFSET = (int)(0.8 * PPCM);
  ARM_LENGTH = (int)(19 * PPCM);
  ARM_HEIGHT = (int)(11.2 * PPCM);
  ARROW_SIZE = (int)(1.4 * PPCM);                // mudei de 2.2
  
  dictionary = loadStrings("words.txt"); //load the dictionary set into memory
  for(String word : dictionary){
    if (m.containsKey(word.charAt(0))){
      ArrayList<String> list = m.get(word.charAt(0));
      list.add(word);
      m.put(word.charAt(0), list);
    }
    else {
      ArrayList<String> list = new ArrayList();
      list.add(word);
      m.put(word.charAt(0), list);
    }  
  } 
}

void draw()
{ 
  // Check if we have reached the end of the study
  if (finishTime != 0)  return;
 
  background(255);                                                         // clear background
  
  // Draw arm and watch background
  imageMode(CENTER);
  image(arm, width/2, height/2, ARM_LENGTH, ARM_HEIGHT);
  
  // Check if we just started the application
  if (startTime == 0 && !mousePressed)
  {
    fill(0);
    textAlign(CENTER);
    text("Tap to start time!", width/2, height/2);
  }
  else if (startTime == 0 && mousePressed) nextTrial();                    // show next sentence
  
  // Check if we are in the middle of a trial
  else if (startTime != 0)
  {
    textAlign(LEFT);
    fill(100);
    text("Phrase " + (currTrialNum + 1) + " of " + NUM_REPEATS, width/2 - 4.0*PPCM, height/2 - 8.1*PPCM);   // write the trial count
    text("Target:    " + currentPhrase, width/2 - 4.0*PPCM, height/2 - 7.1*PPCM);                           // draw the target string
    fill(0);
    String entered = "Entered:  " + currentTyped;
    text(entered,width/2 - 4.0*PPCM, height/2 - 6.1*PPCM);
    fill(175);
    text(letterHover + "|", width/2 - 4.0*PPCM + textWidth(entered), height/2 - 6.1*PPCM); 
  
    // Draw very basic ACCEPT button - do not change this!
    textAlign(CENTER);
    noStroke();
    fill(0, 250, 0);
    rect(width/2 - 2*PPCM, height/2 - 5.1*PPCM, 4.0*PPCM, 2.0*PPCM);
    fill(0);
    text("ACCEPT >", width/2, height/2 - 4.1*PPCM);
    
    inputPrediction();
    
    
    // THIS IS THE ONLY INTERACTIVE AREA (4cm x 4cm); do not change size
    textFont(createFont("Arial", 24));  // set the font to arial 24
    stroke(0, 255, 0);
    noFill();
    rect(width/2 - 1.97*PPCM, height/2 - 1*PPCM, 4.0*PPCM, 3.05*PPCM);
    
    // Write current letter
    textAlign(CENTER);
    fill(0);
    //text("" + currentLetter, width/2, height/2);             
    if(currentLetter != 'y'){                                                          // draw in sets of 6 untyl the letter y
      text("" + currentLetter, width/2 - 1.4*PPCM, height/2 - 0.35*PPCM);              //  draw current letter (a)
      text("" + (char)(currentLetter+1), width/2 - 0.5*PPCM, height/2 - 0.35*PPCM);    //  draw current letter + 1 (b)
      text("" + (char)(currentLetter+2), width/2 + 0.5*PPCM, height/2 - 0.35*PPCM);    //  draw current letter + 2 (c)
      text("" + (char)(currentLetter+3), width/2 - 1.4*PPCM , height/2 + 0.65*PPCM);   //  draw current letter + 3 (d)
      text("" + (char)(currentLetter+4), width/2 - 0.5*PPCM , height/2 + 0.65*PPCM);   //  draw current letter + 4 (e)
      text("" + (char)(currentLetter+5), width/2 + 0.5*PPCM , height/2 + 0.65*PPCM);   //  draw current letter + 5 (f)
     
      stroke(153);
      noFill();
      rect(width/2 - 1.9*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM,15);          //  draw square for current letter
      rect(width/2 - 1.9*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM,15);          //  draw square for current letter + 1
      rect(width/2 - 0.93*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM,15);         //  draw square for current letter + 2
      rect(width/2 - 0.93*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM,15);         //  draw square for current letter + 3
      rect(width/2 + 0.05*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM,15);         //  draw square for current letter + 4
      rect(width/2 + 0.05*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM,15);         //  draw square for current letter + 5
      

    } else {                                                                          // lat page where y and z will be
      text("" + currentLetter, width/2 - 1*PPCM, height/2 + 0.10*PPCM);               //  draw current letter (y)
      text("" + (char)(currentLetter+1), width/2 +0.1*PPCM, height/2 + 0.10*PPCM);    //  draw current letter + 1 (z)
      stroke(153);
      noFill();
      rect(width/2 - 0.35*PPCM, height/2 - 0.4*PPCM, 0.9*PPCM, 0.9*PPCM,15);          //  draw square for current letter (y)
      rect( width/2 -1.45*PPCM, height/2 - 0.4*PPCM, 0.9*PPCM, 0.9*PPCM,15);          //  draw square for current letter + 1 (z)
 
    }  
      textFont(createFont("Arial", 18));  // set the font to arial 24
      stroke(153);
      noFill();
      color orange = color(240,160,40);
      fill(orange);
      rect(width/2 - 0.90 * PPCM, height/2 + 1.1 * PPCM, 1.8*PPCM, 0.80*PPCM, 15);  //  draw square for space button
      color red = color(220, 60, 60);
      fill(red);
      rect(width/2 + 1.03*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM,15);       //  draw square for delete button
      fill(255);
      text("DEL", width/2 + 1.5*PPCM, height/2 - 0.33*PPCM);                        //  draw delete (DEL)
      text("space", width/2 , height/2 + 1.6*PPCM);                                //  draw space (_)

          
    // Draw next and previous arrows
    letterHoverFunc();
    noFill();
    imageMode(CORNER);
    image(leftArrow, width/2 - 0.76 * PPCM - ARROW_SIZE, height/2 + 0.79 * PPCM, ARROW_SIZE, ARROW_SIZE);    //  draw left arrow
    image(rightArrow, width/2 + 0.78 * PPCM, height/2 + 0.8 * PPCM, ARROW_SIZE, ARROW_SIZE);  //  draw right arrow
    image(checkIcon, width/2 + PPCM, height/2 + 0.15*PPCM, ARROW_SIZE * 0.7, 0.9 * ARROW_SIZE * 0.65);
  }
  
  // Draw the user finger to illustrate the issues with occlusion (the fat finger problem)
  imageMode(CORNER);
  image(fingerOcclusion, mouseX - FINGER_OFFSET, mouseY - FINGER_OFFSET, FINGER_SIZE, FINGER_SIZE);
}

// Check if mouse click was within certain bounds
boolean didMouseClick(float x, float y, float w, float h)
{
  return (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h);
}

void letterHoverFunc(){
  letterHover = '\0';
  if(currentLetter != 'y'){
       if (didMouseClick(width/2 - 1.9*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM)){                     // if it clicks on the square where currentLetter is located
         letterHover = char(currentLetter);
       }
       else if (didMouseClick(width/2 - 0.93*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM)){               // if it clicks on the square where currentLetter +1 is located
         letterHover = char(currentLetter+1);
       }
       else if (didMouseClick(width/2 + 0.05*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM)){               // [...] currenterLetter + 2
         letterHover = char(currentLetter+2);
       }
       else if (didMouseClick(width/2 - 1.9*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM)){                // [...]
         letterHover = char(currentLetter+3);
       }
       else if (didMouseClick(width/2 - 0.93*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM)){               // [...]
         letterHover = char(currentLetter+4);
       }
       else if (didMouseClick(width/2 + 0.05*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM)){               // [...]
         letterHover = char(currentLetter+5);
       }
    }else{
       if (didMouseClick(width/2 -1.45*PPCM, height/2 - 0.4*PPCM, 0.9*PPCM, 0.9*PPCM)){                    // if it clicks on the square where currentLetter is located
         letterHover = char(currentLetter);
       }
       else if (didMouseClick(width/2 - 0.35*PPCM, height/2 - 0.4*PPCM, 0.9*PPCM, 0.9*PPCM)){              // if it clicks on the square where currentLetter +1 is located
         letterHover = char(currentLetter+1);
       } 
     }
}

void mousePressed()
{
  if (didMouseClick(width/2 - 2*PPCM, height/2 - 5.1*PPCM, 4.0*PPCM, 2.0*PPCM)) {
      nextTrial();                 // Test click on 'accept' button - do not change this!
      currentPrediction = "";
  }
  else if(didMouseClick(width/2 - 2.0*PPCM, height/2 - 1.0*PPCM, 4.0*PPCM, 3.0*PPCM))                        // Test click on 'keyboard' area - do not change this condition! 
  {
    // YOUR KEYBOARD IMPLEMENTATION NEEDS TO BE IN HERE! (inside the condition)
    
    // Test click on left arrow
    if (didMouseClick(width/2 - 0.76 * PPCM - ARROW_SIZE, height/2 + 0.79 * PPCM, ARROW_SIZE, ARROW_SIZE))   // if it clicks on the square where the left arrow is located 
    {
      currentLetter = char(currentLetter - 6);
      if (currentLetter < '_') currentLetter = 'y';                  // wrap around to y
    }
    // Test click on right arrow
    else if (didMouseClick(width/2 + 0.78 * PPCM, height/2 + 0.78 * PPCM, ARROW_SIZE, ARROW_SIZE)){           // if it clicks on the square where the right arrow is located    
      currentLetter = char(currentLetter +6);
      if (currentLetter > 'y') currentLetter = 'a';                  // wrap around to a
    }
    
    else if (didMouseClick(width/2 - 0.90 * PPCM, height/2 + 1.1 * PPCM, 1.8*PPCM, 0.80*PPCM)){              // if it clicks on the square where the space bar is located
        currentTyped += " ";     // if underscore, consider that a space bar
        currentWord = "";
        currentComplete = 0;
        currentPrediction = "";
         
    }
    
    if(currentLetter != 'y'){
       if (didMouseClick(width/2 - 1.9*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM)){                     // if it clicks on the square where currentLetter is located
         currentTyped += currentLetter;          // type currentLetter 
         currentWord += char(currentLetter); 
       }
       else if (didMouseClick(width/2 - 0.93*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM)){               // if it clicks on the square where currentLetter +1 is located
         currentTyped += char(currentLetter+1);                // type currentLetter + 1
         currentWord += char(currentLetter+1); 
       }
       else if (didMouseClick(width/2 + 0.05*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM)){               // [...] currenterLetter + 2
         currentTyped += char(currentLetter+2);                                                              // [...]
         currentWord += char(currentLetter+2); 
       }
       else if (didMouseClick(width/2 - 1.9*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM)){                // [...]
         currentTyped += char(currentLetter+3);                                                              
         currentWord += char(currentLetter+3);
       }
       else if (didMouseClick(width/2 - 0.93*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM)){               // [...]
         currentTyped += char(currentLetter+4);
         currentWord += char(currentLetter+4); 
       }
       else if (didMouseClick(width/2 + 0.05*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM)){               // [...]
         currentTyped += char(currentLetter+5);
         currentWord += char(currentLetter+5); 
       }
       else if (didMouseClick(width/2 + 1.03*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM) && currentTyped.length() > 0){       // if it clicks on the square where DEL is located and something has been typed already
         currentTyped = currentTyped.substring(0, currentTyped.length() - 1); // [Code given by teachers] Deletes
         if (currentWord.length()==1) currentWord="";
          if (currentWord.length()>0){
            currentWord = currentWord.substring(0, currentWord.length() -1);
          }
         currentComplete = 0;
       }
    }else{
       if (didMouseClick(width/2 -1.45*PPCM, height/2 - 0.4*PPCM, 0.9*PPCM, 0.9*PPCM)){                    // if it clicks on the square where currentLetter is located
         currentTyped += currentLetter;                                                                    // type currentLetter 
         currentWord += char(currentLetter); 
       }
       else if (didMouseClick(width/2 - 0.35*PPCM, height/2 - 0.4*PPCM, 0.9*PPCM, 0.9*PPCM)){              // if it clicks on the square where currentLetter +1 is located
         currentTyped += char(currentLetter+1);                                                            // type currentLetter + 1
         currentWord += char(currentLetter+1); 
       }
       else if (didMouseClick(width/2 + 1.03*PPCM, height/2 - 0.93*PPCM, 0.9*PPCM, 0.9*PPCM) && currentTyped.length() > 0){         // if it clicks on the square where DEL is located and something has been typed already
         currentTyped = currentTyped.substring(0, currentTyped.length() - 1);             // [Code given by teachers] Deletes
         if (currentWord.length()==1) currentWord="";
            if (currentWord.length()>0){
              currentWord = currentWord.substring(0, currentWord.length() -1);
            }
         currentComplete = 0;
       }
     
     }
   if ( startTime!=0 && didMouseClick(width/2 + 1.03*PPCM, height/2 + 0.07*PPCM, 0.9*PPCM, 0.9*PPCM)) {
       if (!currentPrediction.equals("No suggestion")){
         int index = currentTyped.lastIndexOf(currentWord);
         currentTyped = currentTyped.substring(0,index);
         currentTyped += currentPrediction + " ";
         currentWord = currentPrediction;
         currentPrediction = ""; 
       }  
   } 
  }
  else System.out.println("debug: CLICK NOT ACCEPTED");
  
   if(!currentWord.equals(""))
       currentPrediction = "";
}

void inputPrediction(){
    noStroke();
    fill(125);
    rect(width/2 - 2.0*PPCM, height/2 - 2.0*PPCM, 4.0*PPCM, 1.0*PPCM);
    List<String> autocomplete = new ArrayList<String>();
    
    if(!currentWord.equals("") && (currentPrediction.equals("the") ||
             currentPrediction.equals("of") || currentPrediction.equals("and")))
          currentPrediction = "";
         
    if (currentWord.equals("") && currentPrediction.equals("")){
      autocomplete.add("the");
      autocomplete.add("of");
      autocomplete.add("and");
      
      Random rand = new Random();
      currentPrediction = autocomplete.get(rand.nextInt(autocomplete.size()));
    }
    
  
    if (!currentWord.equals("") && currentPrediction.equals("")){
     
      if (!currentWord.equals(currentPrediction)){ 
        
        autocomplete = findCompletions();
          
        Random rand = new Random();
        String noSuggest = "No suggestion";
        if(autocomplete.size() > 0){
          currentPrediction = autocomplete.get(rand.nextInt(autocomplete.size()));
        } else {
          currentPrediction = noSuggest;
        }
      }
    }
    
    if (!currentPrediction.equals("")) {
      if (currentPrediction.equals("No suggestion")){
          fill(50);
          textFont(createFont("Helvetica",  0.4*PPCM)); 
          textAlign(CENTER, CENTER);
          text(currentPrediction, width/2 - 1.36 * PPCM , height/2 - 2.0*PPCM, buttonWidth *2 , PPCM);
      } else {
          fill(255);
          textFont(createFont("Helvetica",  0.4*PPCM));  
          textAlign(CENTER, CENTER);
          text(currentPrediction, width/2 - 1.36 * PPCM , height/2 - 2.0*PPCM, buttonWidth *2 , PPCM);
      }
    }   
}



List findCompletions() {
    List<String> comp = new ArrayList<String>();
    Character c;
  
    c = currentWord.charAt(0);
    ArrayList<String> l = m.get(c);
    for (String s: l) {
      if (s.indexOf(currentWord) == 0 && !s.equals(currentWord)) comp.add(s);
      if (comp.size()==2) break;
    }
  
  return comp;
}


void nextTrial()
{
  if (currTrialNum >= NUM_REPEATS) return;                                            // check to see if experiment is done
  
  // Check if we're in the middle of the tests
  else if (startTime != 0 && finishTime == 0)                                         
  {
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + NUM_REPEATS);
    System.out.println("Target phrase: " + currentPhrase);
    System.out.println("Phrase length: " + currentPhrase.length());
    System.out.println("User typed: " + currentTyped);
    System.out.println("User typed length: " + currentTyped.length());
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim()));
    System.out.println("Time taken on this trial: " + (millis() - lastTime));
    System.out.println("Time taken since beginning: " + (millis() - startTime));
    System.out.println("==================");
    lettersExpectedTotal += currentPhrase.trim().length();
    lettersEnteredTotal += currentTyped.trim().length();
    errorsTotal += computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
    typed[currTrialNum] = currentTyped;
  }
  
  // Check to see if experiment just finished
  if (currTrialNum == NUM_REPEATS - 1)                                           
  {
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + (finishTime - startTime));
    System.out.println("Total letters entered: " + lettersEnteredTotal);
    System.out.println("Total letters expected: " + lettersExpectedTotal);
    System.out.println("Total errors entered: " + errorsTotal);
    
    float wpm = (lettersEnteredTotal / 5.0f) / ((finishTime - startTime) / 60000f);   // FYI - 60K is number of milliseconds in minute
    float freebieErrors = lettersExpectedTotal * .05;                                 // no penalty if errors are under 5% of chars
    float penalty = max(0, (errorsTotal - freebieErrors) / ((finishTime - startTime) / 60000f));
    
    System.out.println("Raw WPM: " + wpm);
    System.out.println("Freebie errors: " + freebieErrors);
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm - penalty));                         // yes, minus, because higher WPM is better: NET WPM
    System.out.println("==================");
    
    printResults(wpm, freebieErrors, penalty);
    
    currTrialNum++;  // increment by one so this mesage only appears once when all trials are done
      
    return;
  }
  
  else if (startTime == 0)                                                            // first trial starting now
  {
    System.out.println("Trials beginning! Starting timer...");
    startTime = millis();                                                             // start the timer!
  } 
  else currTrialNum++;                                                                // increment trial number

  lastTime = millis();                                                                // record the time of when this trial ended
  currentTyped = "";                                                                  // clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum];    // load the next phrase!
  currentWord = "";
  currentComplete = 0;
}
  
  

// Print results at the end of the study
void printResults(float wpm, float freebieErrors, float penalty)
{
  
  float totalTime = (finishTime - startTime) / 1000;  //in seconds
  
  float charPerSecond = lettersEnteredTotal/totalTime;
  
  
  background(0);       // clears screen
  
  textFont(createFont("Arial", 16));    // sets the font to Arial size 16
  fill(255);    //set text fill color to white
  text(day() + "/" + month() + "/" + year() + "  " + hour() + ":" + minute() + ":" + second(), 100, 20);   // display time on screen
  
  text("Finished!", width / 2, height / 2); 
  
  int h = 20;
  for(int i = 0; i < NUM_REPEATS; i++, h += 40 ) {
    text("Target phrase " + (i+1) + ": " + phrases[i], width / 2, height / 2 + h);
    text("User typed " + (i+1) + ": " + typed[i], width / 2, height / 2 + h+20);
  }
  
  text("Characters per Second: " + charPerSecond, width / 2, height / 2 + h+20);
  
  text("Raw WPM: " + wpm, width / 2, height / 2 + h+60);
  text("Freebie errors: " + freebieErrors, width / 2, height / 2 + h+80);
  text("Penalty: " + penalty, width / 2, height / 2 + h+100);
  text("WPM with penalty: " + max((wpm - penalty), 0), width / 2, height / 2 + h+120);

  saveFrame("results-######.png");    // saves screenshot in current folder    
}

// This computes the error between two strings (i.e., original phrase and user input)
int computeLevenshteinDistance(String phrase1, String phrase2)
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++) distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++) distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}
