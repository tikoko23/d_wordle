module wordle;

import std.stdio : writeln, write, readln, readf, File;
import std.range;
import std.string;
import std.conv;
import std.random;
import std.datetime : Clock;

immutable uint WORD_LENGTH = 5;
immutable uint GUESS_COUNT = 6;

enum EscapeColor
{
    green_bg = 42,
    yellow_bg = 43,
    none = 0
}

string esc_format(EscapeColor color)
{
    return "\x1b[" ~ to!string(cast(int) color) ~ "m";
}

string prev;

int[char] get_empty_counts(int[char] cnt)
{
    int[char] new_counts;

    foreach (char key, int _; cnt)
    {
        new_counts[key] = 0;
    }

    return new_counts;
}

bool str_has_char(string str, char match)
{
    foreach (char ch; str)
    {
        if (ch == match) return true;
    }

    return false;
}

bool print_state(string word, int[char] word_letter_count, string input)
{
    bool return_val = false;

    if (input.length == WORD_LENGTH)
    {
        char[WORD_LENGTH] letter_type = repeat(cast(char) 0).take(WORD_LENGTH).array;

        int[char] marked_count = get_empty_counts(word_letter_count);

        // Handle green letters
        foreach (size_t i, char ch; word)
        {
            if (ch == input[i])
            {
                letter_type[i] = 'g';
                ++marked_count[ch];
            }
        }

        // Handle yellow letters
        foreach (size_t i, char ch; input)
        {
            if (str_has_char(word, ch) && marked_count[ch] < word_letter_count[ch])
            {
                letter_type[i] = 'y';
                ++marked_count[ch];
            }
        } 

        uint green_cnt = 0;
        // Create escape string from types
        foreach (size_t i, char type; letter_type)
        {
            string str;

            switch (type)
            {
              case 'g':
                str = esc_format(EscapeColor.green_bg) ~ to!string(input[i]) ~ esc_format(EscapeColor.none);
                ++green_cnt;
                break;
              
              case 'y':
                str = esc_format(EscapeColor.yellow_bg) ~ to!string(input[i]) ~ esc_format(EscapeColor.none);
                break;

              default:
                str = to!string(input[i]);
            }

            prev ~= str;
        }
        
        prev ~= "\n";

        if (green_cnt == WORD_LENGTH) return_val = true;
    }

    write(prev);
    return return_val;
}

int[char] count_word(string w)
{
    int[char] to_return;

    foreach (char ch; w)
    {
        to_return[ch]++;
    }

    return to_return;
}

bool[string] word_exists;
string[] words;

void load_words(string filename)
{
    File file = File(filename, "r");
    
    foreach (char[] line; file.byLine())
    {
        word_exists[to!string(line)] = true;
        words ~= to!string(line);
    }
}

string get_word()
{
    auto rng = Random(cast(uint) Clock.currTime().toUnixTime());
    ulong idx = uniform!"[)"(0, words.length, rng);

    return words[idx];
}

void game()
{
    string msg_str = "";
    string inp = "";
    string word = get_word();

    uint times_guessed = 0;

    int[char] count = count_word(word);
    prev = "";

    while (true)
    {
        writeln();
        write("\x1b[2J");
        writeln("=== Wordle ===");

        bool won = false;
        
        if (inp != "")
            won = print_state(word, count, inp);

        if (times_guessed >= GUESS_COUNT || won)
        {
            writeln("\x1b[1;39mThe word was: \x1b[0m" ~ word ~ "\nPress enter to continue: ");
            char c;
            readf("%c", &c);
            break;
        }

        writeln(msg_str);

        write("\x1b[1;39mEnter your guess: \x1b[0m");

        char[] inp_buf = readln().dup;

        inp_buf.length--;

        inp = to!string(inp_buf);

        if (inp.length != WORD_LENGTH)
        {
            msg_str = prev ~ "\nPlease enter " ~ to!string(WORD_LENGTH) ~ " letters.";
            continue;
        }

        if (inp !in word_exists)
        {
            msg_str = prev ~ "\nPlease enter a valid word.";
            inp = "";
            continue;
        }

        ++times_guessed;
        msg_str = "";
    }
}

void main(string[] args)
{
    load_words("five_letter_words.txt");

    string instructions = "\x1b[0;32mn: Start new game\n\x1b[0;31mq: Quit\n\x1b[1;39mOpition: \x1b[0m";

    menu_loop : while (true)
    {   write("\x1b[2J");
        writeln("=== Wordle Game Menu ===");
        write(instructions);

        char option;
        
        readf("%c", &option);

        switch (option)
        {
          default:
            writeln("Please enter a valid option");
            break;

          case 'q':
            writeln("Quitting...");
            break menu_loop;
            break;

          case 'n':
            game();
            break;
        }
    }
}