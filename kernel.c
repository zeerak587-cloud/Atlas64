/* Atlas32 freestanding kernel */

// =========================
// KERNEL ENTRY
// =========================



typedef unsigned char  u8;
typedef unsigned short u16;
typedef unsigned int   u32;

#include "arch_io.h"
#include "song_data.h"

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define WHITE_ON_BLACK 0x0F
#define BINARY_MAX 1024
#define LINE_MAX 128

u16* video_memory = ARCH_VGA_MEMORY;

int cursor_x = 0;
int cursor_y = 0;
int shift_down = 0;

char command_buffer[LINE_MAX];
char line_buffer[LINE_MAX];
char binary_file[BINARY_MAX];
int binary_size = 0;
int binary_saved = 0;

// =========================
// VGA OUTPUT
// =========================

void update_cursor()
{
    u16 position = cursor_y * VGA_WIDTH + cursor_x;

    outb(0x3D4, 0x0F);
    outb(0x3D5, (u8)(position & 0xFF));
    outb(0x3D4, 0x0E);
    outb(0x3D5, (u8)((position >> 8) & 0xFF));
}

void scroll()
{
    if (cursor_y < VGA_HEIGHT)
        return;

    for (int y = 1; y < VGA_HEIGHT; y++)
    {
        for (int x = 0; x < VGA_WIDTH; x++)
        {
            video_memory[(y - 1) * VGA_WIDTH + x] =
                video_memory[y * VGA_WIDTH + x];
        }
    }

    for (int x = 0; x < VGA_WIDTH; x++)
    {
        video_memory[(VGA_HEIGHT - 1) * VGA_WIDTH + x] =
            (WHITE_ON_BLACK << 8) | ' ';
    }

    cursor_y = VGA_HEIGHT - 1;
}

void put_char(char c)
{
    if (c == '\n')
    {
        cursor_x = 0;
        cursor_y++;
        scroll();
        update_cursor();
        return;
    }

    if (c == '\b')
    {
        if (cursor_x > 0)
        {
            cursor_x--;
            video_memory[cursor_y * VGA_WIDTH + cursor_x] =
                (WHITE_ON_BLACK << 8) | ' ';
        }

        update_cursor();
        return;
    }

    video_memory[cursor_y * VGA_WIDTH + cursor_x] =
        (WHITE_ON_BLACK << 8) | c;

    cursor_x++;

    if (cursor_x >= VGA_WIDTH)
    {
        cursor_x = 0;
        cursor_y++;
    }

    scroll();
    update_cursor();
}

void print(const char* str)
{
    int i = 0;

    while (str[i])
    {
        put_char(str[i]);
        i++;
    }
}

void clear_screen()
{
    for (int y = 0; y < VGA_HEIGHT; y++)
    {
        for (int x = 0; x < VGA_WIDTH; x++)
        {
            video_memory[y * VGA_WIDTH + x] =
                (WHITE_ON_BLACK << 8) | ' ';
        }
    }

    cursor_x = 0;
    cursor_y = 0;
    update_cursor();
}

// =========================
// KEYBOARD INPUT
// =========================

unsigned char keyboard_read()
{
    unsigned char scancode;

    while (1)
    {
        scancode = inb(0x64);

        if (scancode & 1)
            break;
    }

    scancode = inb(0x60);

    return scancode;
}

char scancode_to_ascii(unsigned char sc)
{
    static char map[] =
    {
        0, 27,
        '1','2','3','4','5','6','7','8','9','0','-','=',
        '\b','\t',
        'q','w','e','r','t','y','u','i','o','p','[',']',
        '\n', 0,
        'a','s','d','f','g','h','j','k','l',';','\'', '`',
        0, '\\',
        'z','x','c','v','b','n','m',',','.','/',
        0, '*', 0, ' '
    };

    static char shift_map[] =
    {
        0, 27,
        '!','@','#','$','%','^','&','*','(',')','_','+',
        '\b','\t',
        'Q','W','E','R','T','Y','U','I','O','P','{','}',
        '\n', 0,
        'A','S','D','F','G','H','J','K','L',':','"', '~',
        0, '|',
        'Z','X','C','V','B','N','M','<','>','?',
        0, '*', 0, ' '
    };

    if (sc > 57)
        return 0;

    if (shift_down)
        return shift_map[sc];

    return map[sc];
}

void read_line(char* buffer, int max)
{
    int i = 0;

    while (1)
    {
        unsigned char scancode = keyboard_read();

        if (scancode == 42 || scancode == 54)
        {
            shift_down = 1;
            continue;
        }

        if (scancode == 170 || scancode == 182)
        {
            shift_down = 0;
            continue;
        }

        if (scancode & 0x80)
            continue;

        char c = scancode_to_ascii(scancode);

        if (!c)
            continue;

        if (c == '\n')
        {
            buffer[i] = 0;
            put_char('\n');
            return;
        }

        if (c == '\b')
        {
            if (i > 0)
            {
                i--;
                put_char('\b');
            }

            continue;
        }

        if (i >= max - 1)
            continue;

        buffer[i++] = c;
        put_char(c);
    }
}

// =========================
// STRING UTILITIES
// =========================

int strcmp(const char* a, const char* b)
{
    int i = 0;

    while (a[i] && b[i])
    {
        if (a[i] != b[i])
            return 0;

        i++;
    }

    return a[i] == b[i];
}

int starts_with(const char* text, const char* prefix)
{
    int i = 0;

    while (prefix[i])
    {
        if (text[i] != prefix[i])
            return 0;

        i++;
    }

    return 1;
}

int atoi(const char* text)
{
    int value = 0;
    int i = 0;

    while (text[i] == ' ' || text[i] == '(')
        i++;

    while (text[i] >= '0' && text[i] <= '9')
    {
        value = value * 10 + (text[i] - '0');
        i++;
    }

    return value;
}

void append_char(char c)
{
    if (binary_size >= BINARY_MAX - 1)
        return;

    binary_file[binary_size++] = c;
    binary_file[binary_size] = 0;
}

void append_line(const char* line)
{
    int i = 0;

    while (line[i])
    {
        append_char(line[i]);
        i++;
    }

    append_char('\n');
}

// =========================
// TINY BINARY EDITOR
// =========================

void command_create_file()
{
    clear_screen();
    print("Atlas32 Editor\n");
    print("Commands: print (text), delay (number)\n");
    print("Press Enter on two blank lines to save in RAM.\n\n");

    binary_size = 0;
    binary_saved = 0;
    binary_file[0] = 0;

    int blank_lines = 0;

    while (1)
    {
        print("| ");
        read_line(line_buffer, LINE_MAX);

        if (line_buffer[0] == 0)
        {
            blank_lines++;

            if (blank_lines >= 2)
            {
                binary_saved = 1;
                print("\nSaved binary file in RAM.\n");
                print("Type run binary file to execute it.\n\n");
                return;
            }

            continue;
        }

        blank_lines = 0;
        append_line(line_buffer);
    }
}

u16 pit_read_count()
{
    u8 low;
    u8 high;

    outb(0x43, 0x00);
    low = inb(0x40);
    high = inb(0x40);

    return ((u16)high << 8) | low;
}

void pit_init_100hz()
{
    u16 divisor = 11932;

    outb(0x43, 0x34);
    outb(0x40, (u8)(divisor & 0xFF));
    outb(0x40, (u8)((divisor >> 8) & 0xFF));
}

void wait_pit_ticks(int ticks)
{
    int elapsed = 0;
    u16 last = pit_read_count();

    while (elapsed < ticks)
    {
        u16 now = pit_read_count();

        if (now > last)
        {
            elapsed++;
        }

        last = now;
    }
}

void delay_seconds(int seconds)
{
    if (seconds < 1)
        return;

    wait_pit_ticks(seconds * 100);
}

void speaker_on(u16 frequency)
{
    u16 divisor;
    u8 speaker_state;

    if (frequency < 20)
        return;

    divisor = (u16)(1193180 / frequency);

    outb(0x43, 0xB6);
    outb(0x42, (u8)(divisor & 0xFF));
    outb(0x42, (u8)((divisor >> 8) & 0xFF));

    speaker_state = inb(0x61);
    outb(0x61, speaker_state | 3);
}

void speaker_off()
{
    outb(0x61, inb(0x61) & 0xFC);
}

void play_song_notes()
{
    for (int i = 0; i < SONG_NOTE_COUNT; i++)
    {
        u16 frequency = song_notes[i][0];
        u16 ticks = song_notes[i][1];

        if (frequency)
            speaker_on(frequency);
        else
            speaker_off();

        wait_pit_ticks(ticks);
    }

    speaker_off();
}

void run_script_line(char* line)
{
    if (starts_with(line, "print ("))
    {
        int i = 7;

        while (line[i] && line[i] != ')')
        {
            put_char(line[i]);
            i++;
        }

        put_char('\n');
        return;
    }

    if (starts_with(line, "delay ("))
    {
        delay_seconds(atoi(line + 6));
        return;
    }

    print("Unknown binary command: ");
    print(line);
    put_char('\n');
}

void command_run_binary_file()
{
    if (!binary_saved)
    {
        print("No binary file saved in RAM\n");
        return;
    }

    print("Running binary file...\n");

    char run_line[LINE_MAX];
    int source = 0;
    int target = 0;

    while (binary_file[source])
    {
        target = 0;

        while (binary_file[source] && binary_file[source] != '\n' && target < LINE_MAX - 1)
        {
            run_line[target++] = binary_file[source++];
        }

        run_line[target] = 0;

        if (binary_file[source] == '\n')
            source++;

        if (run_line[0])
            run_script_line(run_line);
    }

    print("Binary finished.\n");
}

// =========================
// COMMANDS
// =========================

u8 rtc_read(u8 reg)
{
    outb(0x70, reg);
    return inb(0x71);
}

u8 bcd_to_bin(u8 value)
{
    return (value & 0x0F) + ((value >> 4) * 10);
}

void command_time()
{
    u8 second = bcd_to_bin(rtc_read(0x00));
    u8 minute = bcd_to_bin(rtc_read(0x02));
    u8 hour   = bcd_to_bin(rtc_read(0x04));

    print("Time: ");

    put_char('0' + (hour / 10));
    put_char('0' + (hour % 10));
    put_char(':');
    put_char('0' + (minute / 10));
    put_char('0' + (minute % 10));
    put_char(':');
    put_char('0' + (second / 10));
    put_char('0' + (second % 10));
    put_char('\n');
}

void command_reboot()
{
    print("Rebooting...\n");

    outb(0x64, 0xFE);

    for (;;)
    {
    }
}

void command_help()
{
    print("Commands:\n");
    print("help\n");
    print("clear\n");
    print("create file\n");
    print("run binary file\n");
    print("play song\n");
    print("about\n");
    print("time\n");
    print("reboot\n");
    print("creator\n");
}

void command_about()
{
    print("Atlas32 32-bit protected mode kernel\n");
    print("Written in Assembly and C\n");
}

void command_play_song()
{
    print("Playing song...\n");
    play_song_notes();
    print("Song finished.\n");
}

void command_creator()
{
    print("creator biography\n");
    print("\n");
    print("Name: Zeerak Khan\n");
    print("Started coding at 6, made this when 9\n");
    print("Follow me at https://scratch.mit.edu/users/Cute_Seal_WOW/\n");
    print("Or follow me at https://github.com/zeerak587-cloud\n");
    print("Thank You!\n");
}

void execute_command(char* cmd)
{
    if (strcmp(cmd, "time"))
    {
        command_time();
        return;
    }
    
    if (strcmp(cmd, "creator"))
    {
        command_creator();
        return;
    }

    if (strcmp(cmd, "reboot"))
    {
        command_reboot();
        return;
    }
    
    if (strcmp(cmd, "help"))
    {
        command_help();
        return;
    }

    if (strcmp(cmd, "clear"))
    {
        clear_screen();
        return;
    }

    if (strcmp(cmd, "create file"))
    {
        command_create_file();
        return;
    }

    if (strcmp(cmd, "run binary file"))
    {
        command_run_binary_file();
        return;
    }

    if (strcmp(cmd, "play song"))
    {
        command_play_song();
        return;
    }

    if (strcmp(cmd, "about"))
    {
        command_about();
        return;
    }

    print("Unknown command\n");
}

void kernel_main()
{
    pit_init_100hz();
    clear_screen();

    print("Atlas32\n");
    print("32-bit protected mode kernel\n\n");

    print("Type help for commands\n\n");

    while (1)
    {
        print("> ");

        read_line(command_buffer, LINE_MAX);

        execute_command(command_buffer);
    }
}
