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
 * Common Erlang->C port communications declarations
 */

#ifndef EFRAMER_H
#define EFRAMER_H

#include <stdint.h>
#include <stdlib.h>

/*
 * Erlang port framing configuration
 */
struct eframer_config {
    size_t max_rx_message_size;
    size_t max_tx_message_size;

    void (*rx_handler)(const uint8_t *data, size_t len, void *cookie);
    void *cookie;
};

struct eframer {
    uint8_t *rx;
    uint8_t *tx;

    size_t index;

    struct eframer_config config;
};

void eframer_init(struct eframer *handler,
                  const struct eframer_config *config);
void eframer_free(struct eframer *ef);
uint8_t *eframer_tx_buffer(struct eframer *ef);
void eframer_send(struct eframer *ef, size_t payload_len);

void eframer_process(struct eframer *ef);

#endif
