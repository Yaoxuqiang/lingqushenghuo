package com.hmdp.consumer;

import com.hmdp.entity.VoucherOrder;
import com.hmdp.service.IVoucherOrderService;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;

@Slf4j
@Component
// @KafkaListener(id = "multiGroup", topics = "greeting")
public class SeckillVoucherConsumer {

    @Resource
    private IVoucherOrderService voucherOrderService;

    /**
     * 【秒杀链路消息队列使用】-3
     * Kafka 监听消费秒杀订单消息
     * 指定之前创建的containerFactory
     */
    /*@KafkaListener(
            containerFactory = "seckillVoucherOrderKafkaListenerContainerFactory",
            topics = "seckill-voucher-order"
    )*/
    public void processMessage(ConsumerRecord<String, Object> record, Acknowledgment ack) {
        try {
            // 获取消息内的数据
            VoucherOrder order = (VoucherOrder) record.value();
            // 生成订单 扣减库存 等等操作
            voucherOrderService.createVoucherOrder(order);
            // 业务成功后提交确认ack
            ack.acknowledge();
        } catch (Exception e) {
            log.error("消费异常: topic={}, offset={}, 原因={}", record.topic(), record.offset(), e.getMessage());
            // 不要 acknowledge(), 直接让异常向上抛出, 让 errorHandler 处理
            throw new RuntimeException("Deserialization failed", e);
        }
    }
}