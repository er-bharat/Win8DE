#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

struct Memory {
    char *data;
    size_t size;
};

static size_t write_callback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t total = size * nmemb;
    struct Memory *mem = (struct Memory *)userp;

    char *ptr = realloc(mem->data, mem->size + total + 1);
    if(!ptr) return 0; // out of memory

    mem->data = ptr;
    memcpy(&(mem->data[mem->size]), contents, total);
    mem->size += total;
    mem->data[mem->size] = 0;

    return total;
}

int main() {
    CURL *curl;
    CURLcode res;
    struct Memory chunk = {0};

    // Google Calendar ICS for Indian Holidays
    const char *url = "https://calendar.google.com/calendar/ical/en-in.indian%23holiday%40group.v.calendar.google.com/public/basic.ics";

    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();
    if(curl) {
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_callback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);

        res = curl_easy_perform(curl);
        if(res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            return 1;
        }

        curl_easy_cleanup(curl);
    }
    curl_global_cleanup();

    // Open JSON file to write
    FILE *fp = fopen("indian_holidays.json", "w");
    if(!fp) {
        perror("Cannot open file");
        free(chunk.data);
        return 1;
    }

    fprintf(fp, "[\n");

    // Parse ICS
    char *line = strtok(chunk.data, "\n");
    int in_event = 0;
    char event_date[16] = "";
    char event_name[256] = "";
    int first = 1;

    while(line) {
        if(strncmp(line, "BEGIN:VEVENT", 12) == 0) {
            in_event = 1;
            event_date[0] = 0;
            event_name[0] = 0;
        }
        else if(strncmp(line, "END:VEVENT", 10) == 0) {
            in_event = 0;
            if(event_date[0] != 0 && event_name[0] != 0) {
                if(!first) fprintf(fp, ",\n");
                fprintf(fp, "  {\"date\": \"%s\", \"name\": \"%s\"}", event_date, event_name);
                first = 0;
            }
        }
        else if(in_event) {
            if(strncmp(line, "DTSTART;VALUE=DATE:", 19) == 0) {
                strcpy(event_date, line + 19);
            }
            else if(strncmp(line, "SUMMARY:", 8) == 0) {
                strcpy(event_name, line + 8);
            }
        }
        line = strtok(NULL, "\n");
    }

    fprintf(fp, "\n]\n");
    fclose(fp);
    free(chunk.data);

    printf("JSON file 'indian_holidays.json' created successfully.\n");
    return 0;
}
