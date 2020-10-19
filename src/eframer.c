/*
 *  Copyright 2020 Frank Hunleth
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Common Erlang->C port communications code
 */

#include "eframer.h"

#include <err.h>
#include <stdint.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

/**
 * Initialize an Erlang framing ef.
 *
 * @param ef the structure to initialize
 * @param config configuration
 */
void eframer_init(struct eframer *ef,
                  const struct eframer_config *config)
{
    size_t header_size = sizeof(uint16_t);

    ef->rx = malloc(config->max_rx_message_size + header_size);
    ef->tx = malloc(config->max_tx_message_size + header_size);
    ef->index = 0;
    ef->config = *config;
}

uint8_t *eframer_tx_buffer(struct eframer *ef)
{
    return ef->tx + sizeof(uint16_t);
}

void eframer_free(struct eframer *ef)
{
    free(ef->rx);
    ef->rx = NULL;
}

/**
 * @brief Synchronously send a response back to Erlang
 *
 * @param response what to send back
 */
void eframer_send(struct eframer *ef, size_t payload_len)
{
    uint16_t be_len = htons(payload_len);
    memcpy(ef->tx, &be_len, sizeof(be_len));

    size_t len = sizeof(uint16_t) + payload_len;
    size_t wrote = 0;
    do {
        ssize_t amount_written = write(STDOUT_FILENO, ef->tx + wrote, len - wrote);
        if (amount_written < 0) {
            if (errno == EINTR)
                continue;

            exit(EXIT_FAILURE);
        }

        wrote += amount_written;
    } while (wrote < len);
}

/**
 * @brief Dispatch commands in the buffer
 * @return the number of bytes processed
 */
static size_t eframer_try_dispatch(struct eframer *ef)
{
    /* Check for length field */
    if (ef->index < sizeof(uint16_t))
        return 0;

    uint16_t be_len;
    memcpy(&be_len, ef->rx, sizeof(uint16_t));
    size_t payload_len = ntohs(be_len);
    size_t message_len = sizeof(uint16_t) + payload_len;

    if (message_len > ef->config.max_rx_message_size)
        errx(EXIT_FAILURE, "Message too long (%d bytes)", (int) message_len);

    /* Check whether we've received the entire message */
    if (message_len <= ef->index) {
        ef->config.rx_handler(ef->rx + sizeof(uint16_t), payload_len, ef->config.cookie);
        return message_len;
    } else {
        return 0;
    }
}

/**
 * @brief call to process any new requests from Erlang
 */
void eframer_process(struct eframer *ef)
{
    ssize_t amount_read = read(STDIN_FILENO, ef->rx + ef->index,
                               ef->config.max_rx_message_size - ef->index);

    if (amount_read < 0) {
        /* EINTR is ok to get, since we were interrupted by a signal. */
        if (errno == EINTR)
            return;

        /* Everything else is unexpected. */
        err(EXIT_FAILURE, "read");
    } else if (amount_read == 0) {
        /* EOF. Erlang process was terminated. This happens after a release or if there was an error. */
        exit(EXIT_SUCCESS);
    }

    ef->index += amount_read;
    for (;;) {
        size_t bytes_processed = eframer_try_dispatch(ef);

        if (bytes_processed == 0) {
            /* Only have part of the command to process. */
            break;
        } else if (ef->index > bytes_processed) {
            /* Processed the command and there's more data. */
            memmove(ef->rx, &ef->rx[bytes_processed], ef->index - bytes_processed);
            ef->index -= bytes_processed;
        } else {
            /* Processed the whole buffer. */
            ef->index = 0;
            break;
        }
    }
}
